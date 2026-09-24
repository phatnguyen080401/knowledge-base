---
title: dbt-databricks Adapter
tags: [data-engineering, integration]
created: 2026-09-24 10:19:20
updated: 2026-09-24 10:19:20
---

# dbt-databricks Adapter

`dbt-databricks` is the adapter that connects [[concepts/dbt|dbt (Data Build Tool)]] to the Databricks Lakehouse Platform. It is maintained by Databricks, builds on the generic `dbt-spark` adapter, and adds Databricks-specific capability: Unity Catalog three-level namespacing, Delta Lake as the default file format, SQL warehouse connectivity through the `databricks-sql-connector`, and Databricks-native authentication including OAuth.

## Why a Dedicated Adapter

`dbt-spark` can technically talk to Databricks, but `dbt-databricks` is the supported path and the one Databricks tests against. It defaults models to Delta, supports Unity Catalog (`catalog.schema.table`), exposes Databricks-only model configs such as `liquid_clustering` and `tblproperties`, handles Databricks OAuth, and can route different models to different compute.

## Installation

The adapter is a Python package and pulls in `dbt-core`, the Databricks SQL connector, and the Databricks SDK:

```bash
python -m venv .venv && source .venv/bin/activate
pip install dbt-databricks
dbt --version        # confirms dbt-core and the databricks adapter plugin
```

Pin both packages in `requirements.txt` so environments stay reproducible:

```text
dbt-core==1.9.*
dbt-databricks==1.9.*
```

Adapter minor versions track dbt Core minor versions, so upgrade them together. `dbt init` scaffolds a project and interactively prompts for the connection values described below.

## Gathering Connection Details

Everything needed to connect comes from one place in the Databricks workspace: open the **SQL warehouse** (or all-purpose cluster) → **Connection details** tab.

- **Server hostname** → the `host` value, e.g. `adb-1234567890123456.7.azuredatabricks.net`. Enter it without the `https://` prefix.
- **HTTP path** → the `http_path` value. A SQL warehouse looks like `/sql/1.0/warehouses/a1b2c3d4e5f6g7h8`; an all-purpose cluster looks like `/sql/protocolv1/o/1234567890123456/0123-456789-abcdefgh`.

Prefer a SQL warehouse over an all-purpose cluster for dbt runs: it starts faster, scales independently, and is billed for SQL workloads. All-purpose clusters are only necessary for Python models.

## Configuring the Connection

The adapter is configured in `profiles.yml`, which lives outside the repository — `~/.dbt/profiles.yml` by default, or wherever `DBT_PROFILES_DIR` points. The profile name must match the `profile:` key in `dbt_project.yml`.

```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: databricks
      host: adb-1234567890123456.7.azuredatabricks.net
      http_path: /sql/1.0/warehouses/a1b2c3d4e5f6g7h8
      catalog: analytics_dev          # Unity Catalog; omit for hive_metastore
      schema: dbt_jdoe                # required — the default target schema
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
      threads: 8
```

Validate it before writing any models:

```bash
dbt debug          # checks the profile, credentials, and connectivity
dbt run --empty    # builds the DDL against zero rows to smoke-test the project
```

### Connection Parameters

| Parameter          | Required | Purpose                                                                                 |
| ------------------ | -------- | --------------------------------------------------------------------------------------- |
| `type`             | Yes      | Must be `databricks`                                                                     |
| `host`             | Yes      | Workspace server hostname, no scheme and no trailing slash                               |
| `http_path`        | Yes      | HTTP path of the SQL warehouse or all-purpose cluster                                    |
| `schema`           | Yes      | Default schema (database) models are built into                                          |
| `catalog`          | No       | Unity Catalog catalog; falls back to `hive_metastore` when omitted                       |
| `token`            | Cond.    | Personal access token — required for token authentication                                |
| `auth_type`        | Cond.    | Set to `oauth` to use OAuth instead of a token                                           |
| `client_id`        | Cond.    | OAuth client ID (service principal application ID for M2M)                               |
| `client_secret`    | Cond.    | OAuth client secret for M2M                                                              |
| `threads`          | No       | Concurrent model builds; 4–16 is typical, bounded by warehouse size                      |
| `connect_retries`  | No       | Retries when the connection fails — useful while a warehouse is cold-starting            |
| `connect_timeout`  | No       | Seconds to wait for a connection, including warehouse startup                            |
| `retry_all`        | No       | Retry all connection errors, not just the ones known to be transient                     |
| `session_properties` | No     | Spark/SQL session settings applied to every connection                                   |
| `http_headers`     | No       | Extra HTTP headers, occasionally required by a proxy                                     |
| `compute`          | No       | Named alternative compute targets that models can select per-model                        |

### Multiple Compute Targets

A `compute` block lets expensive models run on a larger warehouse without changing the default:

```yaml
      compute:
        heavy:
          http_path: /sql/1.0/warehouses/big-warehouse-id
```

A model then opts in with `{{ config(databricks_compute='heavy') }}`.

## Token-Based Authentication

A Databricks **personal access token (PAT)** is the simplest method and the one `dbt init` suggests.

1. In the workspace, go to **Settings → Developer → Access tokens → Generate new token**.
2. Give it a comment and a lifetime. Always set an expiry.
3. Copy the token — it starts with `dapi` and is shown exactly once.

```yaml
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
```

```bash
export DBT_DATABRICKS_TOKEN='dapi...'
```

A PAT carries the full identity and permissions of the user or service principal that created it, so treat it as a password:

- Read it from an environment variable or secret manager with `env_var()`; never write the literal into `profiles.yml`, and never commit `profiles.yml`.
- Use a **service principal** token for scheduled production runs, not a human's token — otherwise every pipeline breaks the day that person leaves.
- Set a short lifetime and rotate on a schedule. Tokens are long-lived bearer credentials with no refresh mechanism, which is why OAuth is the better production choice.

## OAuth Authentication

OAuth replaces a static token with short-lived, automatically refreshed credentials. The adapter supports two flavours, both enabled with `auth_type: oauth`.

### OAuth M2M (Client Credentials)

Machine-to-machine is the production pattern: a **service principal** authenticates with a client ID and secret, and the adapter exchanges them for a short-lived access token on each run. No human is in the loop, so it works under a scheduler.

Set-up in Databricks:

1. Create a service principal (account console → **User management → Service principals**, or an existing SCIM-provisioned one).
2. Generate an **OAuth secret** for it, recording the **Client ID** (its application ID) and **Client secret**.
3. Grant it what dbt needs: `CAN USE` on the SQL warehouse, `USE CATALOG` and `USE SCHEMA` on the targets, plus `CREATE TABLE`, `CREATE VIEW`, and `MODIFY` on the schemas it writes to, and `SELECT` on the sources it reads.

```yaml
my_project:
  target: prod
  outputs:
    prod:
      type: databricks
      host: adb-1234567890123456.7.azuredatabricks.net
      http_path: /sql/1.0/warehouses/a1b2c3d4e5f6g7h8
      catalog: analytics
      schema: marts
      auth_type: oauth
      client_id: "{{ env_var('DBT_DATABRICKS_CLIENT_ID') }}"
      client_secret: "{{ env_var('DBT_DATABRICKS_CLIENT_SECRET') }}"
      threads: 8
```

The client secret still needs protecting, but it is scoped to a non-human identity, is exchanged for tokens that expire in minutes, and can be rotated without touching the principal's permissions.

### OAuth U2M (Browser Flow)

User-to-machine suits local development: omit the credentials and the adapter opens a browser for the user to log in, then caches the resulting short-lived token.

```yaml
      auth_type: oauth
      # no token, no client_secret — a browser login is triggered on first run
```

Because it needs an interactive browser, U2M cannot be used in CI or a scheduler. The usual arrangement is U2M on developer machines against a dev catalog, and M2M for CI and production.

### Choosing Between Them

| | PAT | OAuth U2M | OAuth M2M |
| --- | --- | --- | --- |
| Credential lifetime | Long-lived | Short-lived, auto-refreshed | Short-lived, auto-refreshed |
| Works unattended | Yes | No | Yes |
| Identity | User or service principal | The logged-in user | Service principal |
| Best for | Quick start, throwaway experiments | Local development | CI and production |

## Databricks-Specific Model Configuration

Beyond connection setup, the adapter exposes platform features in `config()`:

- `file_format` — `delta` by default; `parquet`, `hudi`, and others are available on the Hive metastore.
- `incremental_strategy` — `merge` (default on Delta), `append`, `insert_overwrite`, `replace_where`, and `microbatch`.
- `partition_by`, `clustered_by` / `buckets`, and `liquid_clustering` for physical layout.
- `location_root` for external tables, `tblproperties` for Delta table properties, and `databricks_tags` for governance tagging.
- Python models, which run on compute rather than a SQL warehouse; `submission_method` selects an all-purpose cluster, a job cluster, serverless, or a workflow job.

## Common Problems

- **`host` includes `https://`** — strip the scheme; the connector adds it.
- **Table not found despite existing** — the `catalog` is unset, so the adapter is looking in `hive_metastore` rather than Unity Catalog.
- **First run times out** — the SQL warehouse is cold-starting; raise `connect_timeout` and `connect_retries`.
- **`PERMISSION_DENIED` under OAuth** — the service principal has warehouse access but is missing `USE CATALOG`/`USE SCHEMA` or `CREATE` on the target schema.
- **Works locally, fails in CI** — the profile is configured for U2M OAuth, which cannot complete a browser flow in a runner. Use M2M there.
- **Token suddenly invalid** — the PAT expired or the user who issued it was deactivated.

## Related Concepts

- [[concepts/dbt|dbt (Data Build Tool)]] — the framework this adapter plugs into; all model, test, and materialization behaviour comes from there

## References

- [dbt — Databricks setup](https://docs.getdbt.com/docs/core/connect-data-platform/databricks-setup)
- [Databricks — Connect to dbt Core](https://docs.databricks.com/aws/en/partners/prep/dbt)
- [dbt-databricks on GitHub](https://github.com/databricks/dbt-databricks)
