---
title: BigQuery Usage and Cost Monitoring
tags: [data-engineering, data-warehouse]
created: 2026-10-20 14:40:40
updated: 2026-10-20 14:40:40
---
# BigQuery Usage and Cost Monitoring

BigQuery charges for bytes scanned rather than for provisioned hardware, so spend is a property of the queries people run, not of a cluster someone sized. Attributing that spend means reading the job history that BigQuery publishes through its `INFORMATION_SCHEMA` views — a form of operational [[concepts/metadata_management|Metadata Management]] that answers who ran what, how much it scanned, and what it is likely to have cost.

## Why It Matters

- **Spend is decentralized.** Any analyst with query access can scan a terabyte by accident. Without per-job attribution there is no way to tell a $2,000 invoice line apart from the one query that caused it.
- **The invoice is too coarse and too late.** Cloud Billing shows a daily total per SKU. Job history shows the individual query, its author, and its destination table, within minutes of execution.
- **It drives the fixes.** The same view that prices a query also exposes *why* it was expensive — a missing partition filter, a `SELECT *` over a wide table, a scheduled job rebuilding everything nightly.
- **It is the feedback loop for guardrails.** Measurements from job history are what justify setting `maximum_bytes_billed`, partitioning a fact table, or moving a workload onto a reservation.

## The `INFORMATION_SCHEMA` Job Views

Job metadata lives in a set of region-qualified views. The region prefix is part of the table path and must be backtick-quoted, because the hyphen in `region-us` would otherwise parse as subtraction:

```sql
FROM `region-us`.INFORMATION_SCHEMA.JOBS
```

| View                    | Scope                                                              | Typical use                            |
| ----------------------- | ------------------------------------------------------------------ | -------------------------------------- |
| `JOBS`                  | All jobs submitted in the current project (formerly `JOBS_BY_PROJECT`) | Per-project chargeback and auditing |
| `JOBS_BY_USER`          | Only jobs submitted by the caller                                  | Self-service checks without elevated permissions |
| `JOBS_BY_FOLDER`        | All jobs in the folder containing the current project              | Departmental rollups                   |
| `JOBS_BY_ORGANIZATION`  | All jobs across the organization                                   | Central FinOps reporting               |

Three constraints shape every query against them:

- **Region.** The prefix must match the region the jobs ran in. A `region-us` query will not see jobs executed in `region-asia-southeast1`; multi-region coverage means querying each region and unioning the results.
- **Retention.** Job metadata is kept for **180 days**. Anything longer-term has to be materialized into a table of your own on a schedule.
- **Permissions.** Seeing other users' jobs requires `bigquery.jobs.listAll` on the project, granted by `roles/bigquery.admin`. Without it, only `JOBS_BY_USER` returns rows.

## The Baseline Query

A single query over `JOBS` gives per-job cost attribution:

```sql
SELECT
    project_id,
    user_email,
    SPLIT(user_email, '@')[OFFSET(0)] AS user_name,
    job_id,
    destination_table.dataset_id AS destination_table_dataset_id,
    destination_table.table_id   AS destination_table_id,
    DATETIME(creation_time) AS date_time,
    job_type,
    statement_type,
    priority,
    query,
    state,
    total_bytes_processed,
    total_bytes_billed,
    total_bytes_processed / POW(1024, 3) AS processed_gib,
    total_bytes_billed   / POW(1024, 3) AS billed_gib,
    (total_bytes_billed  / POW(1024, 4)) * 6.25 AS estimated_cost_usd
FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP('2023-03-01')
ORDER BY creation_time DESC, total_bytes_billed DESC
```

> [!tip] Filter on `creation_time` directly
> The views are partitioned on `creation_time`. Wrapping it in a function — `WHERE DATE(creation_time) >= '2023-03-01'` — defeats partition pruning and makes the metadata query itself slower and more expensive than it needs to be. Compare the raw `TIMESTAMP` instead.

### Column Reference

| Column                           | Meaning                                                                 |
| -------------------------------- | ----------------------------------------------------------------------- |
| `project_id`                     | The project the job was executed in — the project that is billed         |
| `user_email`                     | The identity that submitted the job: a person, or a service account      |
| `user_name`                      | The local part of `user_email`, split off at the `@`. A convenience label, not a real display name — service accounts yield an opaque string |
| `job_id`                         | Unique job identifier; the key for joining to logs or the console        |
| `destination_table_dataset_id`   | Dataset holding the job's destination table                              |
| `destination_table_id`           | Destination table. Every query has one — anonymous queries write to a temporary cache table |
| `date_time`                      | When the job was created, as a `DATETIME`                                |
| `job_type`                       | `QUERY`, `LOAD`, `EXTRACT`, or `COPY`. Only `QUERY` jobs incur analysis charges |
| `statement_type`                 | The SQL statement executed — `SELECT`, `INSERT`, `MERGE`, `CREATE_TABLE_AS_SELECT`, `SCRIPT`, and so on |
| `priority`                       | `INTERACTIVE` or `BATCH`. Batch jobs queue for idle capacity and do not count against concurrent-query limits |
| `query`                          | The full SQL text. Useful for grouping, and a reason to treat this view as sensitive — query text can contain literals |
| `state`                          | `PENDING`, `RUNNING`, or `DONE`                                          |
| `total_bytes_processed`          | Bytes the job actually read                                              |
| `total_bytes_billed`             | Bytes charged for. This, not `total_bytes_processed`, is the cost basis   |
| `estimated_cost_usd`             | `total_bytes_billed` converted to TiB and multiplied by the on-demand rate |

## Costing the Bytes Correctly

The arithmetic looks trivial and is easy to get wrong in three separate ways.

**Use binary units.** BigQuery prices per **tebibyte** ($2^{40}$ bytes), not per decimal terabyte ($10^{12}$ bytes). Dividing by `1000000000000` overstates the TiB count — and therefore the cost — by roughly 10%. `POW(1024, 4)` is the correct divisor, and `POW(1024, 3)` for GiB.

**Use the current rate for your region.** On-demand analysis in the US multi-region is **$6.25 per TiB**; it was $5 per TiB before the July 2023 price change, and the figure differs by region. The rate belongs in a small lookup table rather than hard-coded in the query, and should be checked against the published [BigQuery pricing](https://cloud.google.com/bigquery/pricing) page rather than trusted from memory. The first **1 TiB per month per billing account** is free, so the summed estimate is an upper bound on the invoice.

**The formula only applies to on-demand pricing.** Under capacity (Editions) pricing you buy slot-time, not bytes, and `total_bytes_billed` no longer corresponds to anything you are charged. Cost attribution there runs off `total_slot_ms` and `reservation_id`, apportioning the reservation's price across jobs by slot consumption.

### Billing Nuances That Skew the Estimate

- **Minimum charge.** Each query is billed for at least **10 MB per table referenced**, so a swarm of tiny queries costs more than the raw byte counts suggest.
- **Cached results are free.** A cache hit reports `total_bytes_billed = 0` while `total_bytes_processed` may be large. Summing the processed column instead of the billed column inflates the total badly in dashboard-heavy environments.
- **Scripts are counted twice.** A multi-statement query produces a parent job with `statement_type = 'SCRIPT'` plus one child job per statement. Sum one level or the other — filter `parent_job_id IS NULL`, or exclude `SCRIPT` rows — never both.
- **Failed jobs still cost.** A query that errors partway through may have scanned data before failing; filter on `state = 'DONE'` to count completed work, but do not assume failures were free.
- **The views themselves are not free.** `INFORMATION_SCHEMA` queries are not served from cache and carry the 10 MB minimum, so a monitoring dashboard refreshing every minute is itself a line item.

## From Monitoring to Control

Job history tells you what happened; preventing a repeat needs separate mechanisms:

- **`maximum_bytes_billed`** caps a single job and fails it before the scan, rather than after the bill. Setting it in every connection profile — including development — is the single highest-value guardrail. See [[concepts/dbt_bigquery_adapter|dbt-bigquery Adapter]] for where it sits in a dbt project.
- **Custom quotas** cap total bytes billed per project per day, or per user per day, and stop runaway automation that `maximum_bytes_billed` alone would let retry forever.
- **Labels** on datasets, tables, and jobs let the Cloud Billing export attribute spend to a team, domain, or pipeline without parsing SQL text.
- **Partitioning and clustering**, plus `require_partition_filter`, remove the cause rather than capping the symptom — a filtered partition is bytes never scanned.
- **Dry runs** (`--dry_run`, or `dryRun` in the API) return the byte estimate without executing, which is what CI should check before a model is merged.

> [!warning] Estimates are not invoices
> `total_bytes_billed` × rate is a modelling exercise. Storage, streaming inserts, BI Engine, and data-transfer charges are absent from it entirely, free-tier credits are not applied, and committed-use or reservation pricing changes the basis completely. The **Cloud Billing export to BigQuery** is the authoritative record; job history is the diagnostic tool that explains it.

## Related Concepts

- [[concepts/metadata_management|Metadata Management]] — `INFORMATION_SCHEMA` is the warehouse's own metadata catalog; job history is its operational slice
- [[concepts/data_governance|Data Governance]] — cost accountability is a governance policy, and job history is the evidence that enforces it

## References

- [BigQuery — `INFORMATION_SCHEMA` jobs views](https://cloud.google.com/bigquery/docs/information-schema-jobs)
- [BigQuery pricing](https://cloud.google.com/bigquery/pricing)
- [BigQuery — Custom cost controls](https://cloud.google.com/bigquery/docs/custom-quotas)
- [Google Cloud SKU reference — BigQuery analysis](https://cloud.google.com/skus/?currency=USD&filter=bigquery+analysis)
