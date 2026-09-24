---
title: dbt (Data Build Tool)
tags: [data-engineering, integration, data-modeling]
created: 2026-09-24 10:10:13
updated: 2026-09-24 10:32:52
---

# dbt (Data Build Tool)

dbt is a transformation framework that lets teams define data warehouse tables and views as version-controlled SQL `SELECT` statements, then compiles and runs them in dependency order inside the warehouse. It owns the **T** in ELT: it does not move or extract data, it reshapes data that already landed in a warehouse or lakehouse, and it brings software-engineering practice — modularity, testing, code review, CI/CD, and generated documentation — to the analytics layer of a [[concepts/data_architecture|Data Architecture]].

## Why It Matters

- **Analytics code becomes software.** Transformations live in Git instead of in scheduled stored procedures, ad-hoc notebooks, or BI-tool logic that nobody can review.
- **The dependency graph is derived, not declared.** Because models reference each other through a function call rather than a hard-coded table name, dbt infers the DAG automatically; there is no separate orchestration file to keep in sync.
- **Testing is a first-class step, not an afterthought.** Quality assertions sit next to the model they guard, so [[concepts/data_quality|Data Quality]] checks run on every build rather than as a separate, optional project.
- **Lineage and documentation are generated from the code.** The same graph that drives execution also produces a browsable catalog, which is one of the cheapest sources of technical [[concepts/metadata_management|Metadata Management]] a team can get.
- **SQL is the entry barrier.** Analysts who know SQL can own production transformation logic without learning a general-purpose orchestration framework.

## Where dbt Sits in the Stack

| Stage            | Responsibility                                          | Typical tools                              |
| ---------------- | ------------------------------------------------------- | ------------------------------------------ |
| Extract & Load   | Get raw data into the warehouse, unchanged              | Fivetran, Airbyte, Kafka Connect, custom   |
| **Transform**    | **Clean, conform, join, aggregate into usable models**  | **dbt**                                    |
| Orchestrate      | Schedule and sequence jobs across the whole platform    | Airflow, Dagster, dbt Cloud scheduler      |
| Consume          | Dashboards, reverse ETL, ML features                    | Looker, Tableau, Power BI, notebooks       |

dbt relies on the warehouse for all compute — it pushes SQL down and never processes rows itself. This is why it is a natural fit for cloud warehouses with separable storage and compute, and a poor fit for transformations that cannot be expressed as SQL against a single warehouse.

## Core Building Blocks

### Models

A model is a single `.sql` file containing one `SELECT` statement. The filename becomes the relation name; dbt wraps the statement in the appropriate `CREATE TABLE`/`CREATE VIEW` DDL for the target platform.

```sql
-- models/marts/customer_orders.sql
with orders as (
    select * from {{ ref('stg_orders') }}
),
customers as (
    select * from {{ ref('stg_customers') }}
)
select
    customers.customer_id,
    customers.customer_name,
    count(orders.order_id)   as order_count,
    sum(orders.amount)       as lifetime_value
from customers
left join orders using (customer_id)
group by 1, 2
```

Models may also be written in Python on adapters that support it (Snowflake, BigQuery, Databricks), where the model is a function returning a DataFrame.

### `ref()` and `source()`

These two Jinja functions are the heart of dbt:

- `{{ ref('model_name') }}` — resolve another model's fully qualified relation and record an edge in the DAG.
- `{{ source('raw', 'orders') }}` — resolve a raw, dbt-external table declared in a YAML `sources:` block.

Because every dependency goes through them, dbt knows the build order, can swap schemas per environment (dev, CI, prod) without editing SQL, and can compute downstream impact for any change.

### Sources

Declared in YAML, sources name the raw tables the project reads, attach documentation and tests to them, and enable **source freshness** checks (`dbt source freshness`) that fail when a loader has fallen behind a `warn_after` / `error_after` threshold.

### Seeds

Small CSV files checked into the repo and loaded with `dbt seed`. Appropriate for static lookup data — country codes, mappings, exclusion lists — and never for large or frequently changing datasets.

### Snapshots

Snapshots implement **Slowly Changing Dimension Type 2** over a mutable source: each run detects changed rows and closes the previous version with `dbt_valid_from` / `dbt_valid_to` columns. Two strategies exist:

- `timestamp` — trust an `updated_at` column (preferred, cheaper, requires a reliable column).
- `check` — compare a specified list of columns, or all of them.

Snapshots capture history the source system throws away, so they must run on a schedule at least as often as the data changes; a missed window loses that version permanently.

### Tests

- **Generic tests** are reusable assertions applied in YAML. The four built in are `unique`, `not_null`, `accepted_values`, and `relationships` (referential integrity).
- **Singular tests** are ad-hoc `.sql` files that pass when they return zero rows.
- **Unit tests** validate transformation logic against fixed mock inputs and expected outputs, catching logic errors without waiting for bad data to appear.

Tests carry a `severity` of `error` or `warn`, and can be thresholded with `error_if` / `warn_if`. `dbt build` interleaves tests with models so a failing test stops downstream models from being built on bad data.

### Macros, Jinja, and Packages

Models are Jinja-templated SQL, so control flow, loops, and variables are available at compile time. Reusable logic goes into **macros** under `macros/`, and shared macro libraries are installed as **packages** via `packages.yml` — `dbt_utils` (cross-database helpers, extra tests), `dbt_expectations` (Great Expectations–style assertions), `codegen` (scaffold YAML and staging models), and `audit_helper` (compare two relations during a migration) are the common ones.

### Documentation and Exposures

Descriptions written in YAML, plus the compiled DAG, produce a static documentation site (`dbt docs generate` / `dbt docs serve`) with column-level descriptions, the raw and compiled SQL, and an interactive lineage graph. **Exposures** extend that lineage past the warehouse by declaring downstream dashboards, ML jobs, or applications, so impact analysis reaches the consumers.

## Materializations

A materialization decides what DDL dbt emits for a model. It is set in `dbt_project.yml` or per model in a `config()` block.

| Materialization     | What dbt builds                                                | Use when                                                        |
| ------------------- | -------------------------------------------------------------- | --------------------------------------------------------------- |
| `view`              | `CREATE OR REPLACE VIEW`                                        | Cheap, always fresh, light logic; the sensible default           |
| `table`             | Full `CREATE TABLE AS SELECT`, dropped and rebuilt each run     | Query performance matters and a full rebuild is affordable       |
| `incremental`       | Table built once, then only new/changed rows merged in          | Large fact tables where full rebuilds are too slow or expensive  |
| `ephemeral`         | No relation at all — inlined into dependents as a CTE           | Small intermediate logic used by one or two models               |
| `materialized_view` | Platform-native materialized view, refreshed by the warehouse   | The platform can maintain it more cheaply than dbt can rebuild it|

### Incremental Models

An incremental model needs two things: a filter that limits the run to recent data, and a strategy for reconciling it with what is already there.

```sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}

select * from {{ ref('stg_orders') }}
{% if is_incremental() %}
  where updated_at > (select coalesce(max(updated_at), '1900-01-01') from {{ this }})
{% endif %}
```

`is_incremental()` is true only when the relation already exists and the run is not `--full-refresh`. Strategies vary by adapter: `append` (no deduplication), `merge` (upsert on `unique_key`), `delete+insert`, and `insert_overwrite` (replace whole partitions — the cheapest option on BigQuery and Spark).

The recurring hazard is **late-arriving data**: a lookback window narrower than the worst-case source delay silently drops rows. Widen the window, and schedule periodic full refreshes to heal drift.

## Project Layout and Layering

```text
my_project/
├── dbt_project.yml        # project config: name, paths, materializations, vars
├── packages.yml           # external package dependencies
├── models/
│   ├── staging/           # 1:1 with sources — rename, cast, light cleaning
│   ├── intermediate/      # reusable joins and reshaping, not exposed to BI
│   └── marts/             # business-facing facts and dimensions
├── macros/
├── seeds/
├── snapshots/
└── tests/                 # singular tests
```

The convention most teams follow is three layers:

1. **Staging** — one model per source table, materialized as views, doing nothing but renaming, casting, and trivial cleanup. This is the only layer allowed to call `source()`.
2. **Intermediate** — the messy middle: joins, pivots, and fan-out logic factored out so marts stay readable. Not exposed to consumers.
3. **Marts** — the contract with the business, usually dimensional models ([[concepts/master_data_management|Master Data Management]] conformed dimensions belong here), materialized as tables.

`profiles.yml` holds warehouse connection details and credentials, and lives **outside** the repository (by default `~/.dbt/`) so secrets are never committed.

## Governance Features

- **Contracts** enforce a model's column names and data types at build time; the run fails if the SQL drifts from the declared schema.
- **Model versions** let a breaking change ship as `v2` while `v1` keeps serving existing consumers through a deprecation window.
- **Groups and access modifiers** (`private`, `protected`, `public`) restrict which models may reference which, giving an owner per group.
- **Contracts plus exposures plus lineage** are what make dbt usable as an enforcement point for [[concepts/data_governance|Data Governance]] policy rather than just a build tool.

## Running dbt

| Command                | Does                                                                  |
| ---------------------- | --------------------------------------------------------------------- |
| `dbt run`              | Build models                                                          |
| `dbt test`             | Run tests                                                             |
| `dbt build`            | Run seeds, snapshots, models and tests together in DAG order          |
| `dbt seed`             | Load CSV seeds                                                        |
| `dbt snapshot`         | Capture SCD2 history                                                  |
| `dbt source freshness` | Check how stale raw sources are                                       |
| `dbt docs generate`    | Build the documentation site and catalog                              |
| `dbt compile`          | Render Jinja to executable SQL without running it                     |

**Node selection** controls what a command touches: `--select my_model+` (the model and everything downstream), `+my_model` (its ancestors), `tag:finance`, `path:models/marts`, and `state:modified+` — the last comparing against a previous run's `manifest.json` artifact.

That state comparison enables **Slim CI**: on a pull request, build and test only the modified models and their children, and *defer* unmodified `ref()`s to the production relations. It turns a multi-hour full build into a few minutes and is the single highest-value thing to set up after basic tests.

Every invocation writes artifacts to `target/` — `manifest.json` (the full project graph), `run_results.json` (timings and outcomes), and `catalog.json` (column metadata). These are the integration surface for lineage tools, observability platforms, and catalogs.

## dbt Core vs. dbt Cloud

| | dbt Core | dbt Cloud |
| --- | --- | --- |
| Form | Open-source CLI (Apache 2.0) | Managed SaaS |
| Scheduling | Bring your own (Airflow, Dagster, cron, CI) | Built-in scheduler and job runs |
| Authoring | Local editor or IDE | Browser IDE, plus CLI |
| CI | Self-assembled with the state artifacts | Managed CI on pull requests |
| Extras | — | Hosted docs, API, Semantic Layer, cross-project references |
| Cost | Free; you pay for the infrastructure | Seat- and usage-based |

Teams commonly start on Core with Airflow or Dagster invoking it, and move to Cloud when the scheduling, CI, and permissions plumbing stops being worth maintaining.

## Trusted Adapters

An adapter is the plugin that translates dbt's generic materialization logic into a specific platform's SQL dialect, DDL, and connection protocol. dbt Core on its own cannot connect to anything — exactly one adapter is installed per target platform with `pip install dbt-<platform>`, and its minor version tracks the dbt Core minor version.

dbt groups adapters by who stands behind them: **dbt Labs–maintained**, **vendor- or partner-maintained** (often labelled verified or trusted), and **community-maintained**. The tier matters mostly for how quickly an adapter follows a dbt Core release and how much support exists when it breaks.

| Package                                             | Platform                              | What it brings                                                             |
| --------------------------------------------------- | ------------------------------------- | -------------------------------------------------------------------------- |
| [[concepts/dbt_bigquery_adapter\|dbt-bigquery]]      | Google BigQuery                       | Partitioning and clustering configs; partition-level `insert_overwrite`    |
| [[concepts/dbt_databricks_adapter\|dbt-databricks]] | Databricks Lakehouse                  | Unity Catalog namespacing, Delta by default, OAuth auth, per-model compute |

## Strengths and Limits

**Strengths**

- Version control, code review, and CI for transformation logic.
- Automatic DAG construction, so ordering bugs largely disappear.
- Tests and documentation live beside the code and are cheap to keep current.
- Low barrier for SQL-literate analysts; large ecosystem of packages and adapters.

**Limits**

- **Batch and SQL only.** No streaming, and anything not expressible as warehouse SQL (or a supported Python model) belongs elsewhere.
- **Not an orchestrator.** It sequences its own models and nothing else; ingestion, reverse ETL, and cross-system dependencies need a real scheduler.
- **Not extraction or loading.** Raw data must already be in the warehouse.
- **Warehouse cost is easy to hide.** Careless `table` materializations and full refreshes on large models produce surprising bills.
- **Jinja is a genuine complexity tax.** Heavily templated macros become hard to read and harder to debug; compiled SQL is the only ground truth.
- **Tests detect, they do not prevent.** A failing test after the fact is not the same as a constraint upstream, and dbt does nothing about quality at the source system.

## Best Practices

1. Keep staging models thin, one per source table, and let nothing else call `source()`.
2. Never hard-code a table name where `ref()` or `source()` will do — a hard-coded name is an invisible edge in the DAG.
3. Put `unique` and `not_null` on every model's primary key at minimum; add `relationships` tests on foreign keys.
4. Default to `view`, promote to `table` when queries are slow, and to `incremental` only when rebuilds actually hurt.
5. Set up Slim CI early; build-and-test-everything CI stops being run once it gets slow.
6. Write column descriptions as the model is written, not in a documentation sprint that never happens.
7. Prefer a wider incremental lookback window than you think you need, and schedule regular full refreshes.
8. Use contracts and groups on models that other teams depend on, so a rename is caught at build time rather than in a dashboard.

## Related Concepts

- [[concepts/data_quality|Data Quality]] — dbt's test framework is the usual place warehouse-side quality rules are implemented and enforced
- [[concepts/metadata_management|Metadata Management]] — the `manifest.json` and `catalog.json` artifacts feed catalogs and lineage tooling with technical metadata
- [[concepts/data_governance|Data Governance]] — contracts, model groups, and exposures turn governance policy into build-time enforcement
- [[concepts/master_data_management|Master Data Management (MDM)]] — conformed dimensions and golden records are typically materialized as dbt marts
- [[concepts/data_stewardship|Data Stewardship]] — model ownership through groups and YAML owners gives stewards a concrete place to act

## References

- [dbt documentation](https://docs.getdbt.com/)
- [dbt Labs — best practice guides](https://docs.getdbt.com/best-practices)
- [dbt-utils package](https://github.com/dbt-labs/dbt-utils)
