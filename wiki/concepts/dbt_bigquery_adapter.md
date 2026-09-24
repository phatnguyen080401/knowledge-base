---
title: dbt-bigquery Adapter
tags: [data-engineering, integration]
created: 2026-09-24 10:32:52
updated: 2026-09-24 10:32:52
---

# dbt-bigquery Adapter

`dbt-bigquery` is the dbt Labs–maintained adapter that connects [[concepts/dbt|dbt (Data Build Tool)]] to Google BigQuery. It translates dbt's materializations into BigQuery DDL and jobs, and exposes BigQuery's distinctive features to model code: partitioning and clustering, partition-level `insert_overwrite`, per-job cost limits, dataset locations, and Google Cloud's several authentication methods.

## What Makes BigQuery Different

BigQuery's serverless, scan-priced model changes what matters in a dbt project. There is no warehouse to size, so tuning means reducing bytes scanned rather than adding compute: partition, cluster, and filter. It is also the one common target where a careless full-refresh can produce a four-figure bill from a single command, which is why `maximum_bytes_billed` belongs in every profile.

Its naming also differs from the rest of dbt. BigQuery's **project** is dbt's `database`, and BigQuery's **dataset** is dbt's `schema`; the profile accepts either spelling, and model configs use `project`/`dataset`.

## Installation

```bash
python -m venv .venv && source .venv/bin/activate
pip install dbt-bigquery
dbt --version
```

Pin both packages so environments are reproducible, and upgrade them together — adapter minor versions track dbt Core minor versions:

```text
dbt-core==1.9.*
dbt-bigquery==1.9.*
```

## Configuring the Connection

`profiles.yml` lives outside the repository (`~/.dbt/` by default, or `DBT_PROFILES_DIR`), and its top-level key must match `profile:` in `dbt_project.yml`.

```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: my-gcp-project          # BigQuery project = dbt database
      dataset: dbt_jdoe                # BigQuery dataset = dbt schema
      location: US                     # multi-region or region; must match the data
      threads: 8
      priority: interactive
      maximum_bytes_billed: 1000000000 # hard stop at ~1 GB scanned per job
      job_execution_timeout_seconds: 300
      job_retries: 1
```

Verify before writing models:

```bash
dbt debug
dbt run --empty
```

### Connection Parameters

| Parameter                       | Required | Purpose                                                                            |
| ------------------------------- | -------- | ---------------------------------------------------------------------------------- |
| `type`                          | Yes      | Must be `bigquery`                                                                  |
| `method`                        | Yes      | Authentication method — see below                                                   |
| `project` (or `database`)       | Yes      | GCP project that owns the datasets dbt builds into                                  |
| `dataset` (or `schema`)         | Yes      | Default dataset for models                                                          |
| `location`                      | No       | Dataset location (`US`, `EU`, `us-central1`); must match the sources being queried  |
| `threads`                       | No       | Concurrent models; BigQuery tolerates high values, but quotas still apply           |
| `priority`                      | No       | `interactive` (default, fails fast on quota) or `batch` (queued, cheaper on slots)  |
| `maximum_bytes_billed`          | No       | Kills any job that would scan more than this — the main guardrail against runaway cost |
| `job_execution_timeout_seconds` | No       | Abort a query that runs longer than this                                            |
| `job_retries`                   | No       | Retries for transient job failures                                                  |
| `execution_project`             | No       | Bill and run jobs in a different project from the one holding the data              |
| `impersonate_service_account`   | No       | Run as a service principal without holding its key                                  |
| `keyfile` / `keyfile_json`      | Cond.    | Service-account credentials, by path or inline                                      |
| `refresh_token`, `client_id`, `client_secret`, `token_uri` | Cond. | OAuth refresh-token credentials                             |
| `scopes`                        | No       | Override the default OAuth scopes, e.g. to add Drive access for external sheets     |
| `gcs_bucket`, `dataproc_region`, `dataproc_cluster_name`, `submission_method` | No | Required only for Python models, which execute on Dataproc      |

## Authentication Methods

The `method` key selects how the adapter obtains Google credentials.

### `oauth` — Application Default Credentials

The default for local development. dbt uses whatever ADC the environment provides, so no secret ever touches the project.

```bash
gcloud auth application-default login --scopes=\
https://www.googleapis.com/auth/bigquery,\
https://www.googleapis.com/auth/drive.readonly,\
https://www.googleapis.com/auth/cloud-platform
```

```yaml
      method: oauth
```

This also covers workloads running on GCP — Compute Engine, GKE, Cloud Run, Cloud Composer — where the attached service account supplies ADC automatically, and GitHub Actions or other CI using **Workload Identity Federation**, which writes a short-lived ADC file. Keyless authentication is the preferred production pattern.

### `service-account` — Key File

A downloaded JSON key, referenced by path:

```yaml
      method: service-account
      keyfile: /secure/path/dbt-sa.json
```

### `service-account-json` — Inline Key

The same credentials embedded in the profile, which is how they are injected from a secret manager or CI variable:

```yaml
      method: service-account-json
      keyfile_json:
        type: service_account
        project_id: "{{ env_var('GCP_PROJECT') }}"
        private_key_id: "{{ env_var('GCP_PRIVATE_KEY_ID') }}"
        private_key: "{{ env_var('GCP_PRIVATE_KEY') }}"
        client_email: "{{ env_var('GCP_CLIENT_EMAIL') }}"
        client_id: "{{ env_var('GCP_CLIENT_ID') }}"
        auth_uri: https://accounts.google.com/o/oauth2/auth
        token_uri: https://oauth2.googleapis.com/token
        auth_provider_x509_cert_url: https://www.googleapis.com/oauth2/v1/certs
        client_x509_cert_url: ""
```

Service-account keys are long-lived credentials with no expiry, so they are the weakest option: prefer ADC or Workload Identity Federation, and if a key is unavoidable, read it from a secret manager, never commit it, and rotate it on a schedule.

### `oauth-secrets` — Refresh Token

A pre-obtained refresh token exchanged for access tokens at run time. It is tied to a human user's identity, so it is a poor fit for production:

```yaml
      method: oauth-secrets
      refresh_token: "{{ env_var('DBT_GCP_REFRESH_TOKEN') }}"
      client_id: "{{ env_var('DBT_GCP_CLIENT_ID') }}"
      client_secret: "{{ env_var('DBT_GCP_CLIENT_SECRET') }}"
      token_uri: https://oauth2.googleapis.com/token
```

### Impersonation

Any method can be combined with impersonation, so a developer authenticates as themselves but executes as a service account with exactly the right grants:

```yaml
      method: oauth
      impersonate_service_account: dbt-runner@my-gcp-project.iam.gserviceaccount.com
```

The caller needs `roles/iam.serviceAccountTokenCreator` on the target account. This gives production-equivalent permissions in development without distributing a single key.

### Required IAM

Whichever identity dbt runs as needs, at minimum:

- `roles/bigquery.jobUser` on the project that runs the jobs (or `execution_project`).
- `roles/bigquery.dataEditor` on the datasets dbt writes to — dbt creates the target dataset itself if it is missing, which requires the role at project or dataset level.
- `roles/bigquery.dataViewer` on every source dataset it reads.

## BigQuery-Specific Model Configuration

```sql
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={'field': 'order_date', 'data_type': 'date', 'granularity': 'day'},
    cluster_by=['customer_id', 'status'],
    require_partition_filter=true,
    partition_expiration_days=730,
    labels={'domain': 'sales', 'owner': 'analytics'}
) }}
```

- **`partition_by`** accepts a date/timestamp/datetime column with a `granularity` of `hour`, `day`, `month`, or `year`, an integer column via `range_bucket`, or BigQuery's ingestion-time `_PARTITIONTIME`.
- **`cluster_by`** takes up to four columns and sorts data within each partition; it is the cheapest available optimisation after partitioning.
- **`require_partition_filter`** rejects any query that omits a partition filter — the most effective defence against an accidental full-table scan by a downstream consumer.
- **`partition_expiration_days`** and `hours_to_expiration` let BigQuery age data out automatically.
- **`labels`** propagate to the table for cost attribution and [[concepts/metadata_management|Metadata Management]]; `kms_key_name` sets a customer-managed encryption key.
- **`grant_access_to`** configures authorized views, letting a consumer query a view without access to its underlying tables.

### Incremental Strategies

| Strategy           | Behaviour                                                                 | Use when                                                            |
| ------------------ | ------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `merge` (default)  | `MERGE` on `unique_key`; scans the whole target unless a partition filter narrows it | Rows genuinely mutate and the table is moderate in size |
| `insert_overwrite` | Deletes and replaces whole partitions                                      | Partitioned fact tables — usually the cheapest and most predictable   |
| `microbatch`       | Splits the backfill into one job per time slice                            | Large historical reloads that would time out as one query            |

With `insert_overwrite`, either let dbt infer the partitions to replace from the model's results or declare them explicitly with the `partitions` config; adding `copy_partitions: true` uses BigQuery's copy API instead of a query, which is free.

## Cost Control

Cost is the defining operational concern on BigQuery, and most of it is configuration rather than SQL:

1. Set `maximum_bytes_billed` in every profile, including development.
2. Partition every large fact table, and set `require_partition_filter` on it.
3. Prefer `insert_overwrite` over `merge` on partitioned tables; a `merge` without a partition predicate scans everything.
4. Use `view` or `ephemeral` for thin staging logic — a view costs nothing until queried.
5. Give developers their own dataset and a small `--select` habit; `dbt build` across a whole project in dev is a recurring source of surprise spend.
6. Use `priority: batch` for scheduled runs that are not latency-sensitive.
7. Apply `labels` so BigQuery billing export can attribute spend to a model, domain, or team.

## Common Problems

- **`Not found: Dataset ...` on a source that exists** — `location` does not match the dataset's region; a US profile cannot read an EU dataset.
- **`Access Denied: Project ... User does not have bigquery.jobs.create`** — missing `roles/bigquery.jobUser`, the most common first-run failure.
- **`Query exceeded limit for bytes billed`** — `maximum_bytes_billed` did its job; narrow the query rather than raising the limit reflexively.
- **External Google Sheets tables fail under ADC** — the login was scoped to BigQuery only; re-run `gcloud auth application-default login` including the Drive scope.
- **Incremental model rebuilds everything** — `partition_by` is set but the incremental filter does not reference the partition column, so BigQuery cannot prune.
- **Rate-limit errors with high `threads`** — BigQuery table-update quotas are per-table; lower the thread count or spread the writes.

## Related Concepts

- [[concepts/dbt|dbt (Data Build Tool)]] — the framework this adapter plugs into; all model, test, and materialization behaviour comes from there

## References

- [dbt — BigQuery setup](https://docs.getdbt.com/docs/core/connect-data-platform/bigquery-setup)
- [dbt — BigQuery configurations](https://docs.getdbt.com/reference/resource-configs/bigquery-configs)
- [Google Cloud — Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
