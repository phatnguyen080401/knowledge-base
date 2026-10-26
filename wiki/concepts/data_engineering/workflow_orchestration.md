---
title: Workflow Orchestration
tags: [data-engineering, elt, stub]
created: 2026-10-26 23:17:48
updated: 2026-10-26 23:17:48
---

# Workflow Orchestration

Workflow orchestration is the scheduling, sequencing, and monitoring of data pipeline tasks as a
dependency graph across systems. It covers triggering runs, retrying failures, backfilling history,
and recording run state. Tools such as Airflow and Dagster fill this role, coordinating ingestion,
[[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] transformations, and downstream jobs that no
single tool sequences on its own.

## Related Concepts

- [[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] — sequences only its own models, so a platform needs an orchestrator around it
- [[concepts/data_architecture/data_architecture|Data Architecture]] — lists orchestration as one of the cross-cutting concerns where architectures most often fail
- [[concepts/data_governance/data_sanity_check|Data Sanity Check]] — the orchestrator is where a failed check aborts the publish
- [[concepts/data_governance/metadata_management|Metadata Management]] — orchestrators are a source of run history and operational metadata
- [[concepts/software_architecture/idempotency|Idempotency]] — retries and backfills are safe only when each task is idempotent
