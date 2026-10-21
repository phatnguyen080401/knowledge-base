# Index

Every page in `wiki/concepts/`, grouped by domain. Read this first when answering a question —
shortlist from the summaries here, then open only the pages you need.

## Data Governance

- [[concepts/data_governance|Data Governance]] — the operating model for data: principles, roles, frameworks, and the pillars it coordinates.
- [[concepts/data_quality|Data Quality]] — the six dimensions and their checks, where defects originate, and the measure-remediate lifecycle.
- [[concepts/data_security|Data Security]] — classification, access control models, encryption and key management, the de-identification techniques, and the pipeline-specific leaks.
- [[concepts/data_stewardship|Data Stewardship]] — who is accountable: steward vs. owner vs. custodian, operating models, workflows, and metrics.
- [[concepts/master_data_management|Master Data Management (MDM)]] — golden records, entity resolution and survivorship, the four implementation styles, and hierarchy management.
- [[concepts/metadata_management|Metadata Management]] — the four metadata types, glossary vs. dictionary vs. catalog, lineage capture methods, and active vs. passive metadata.

## Data Architecture

- [[concepts/data_architecture|Data Architecture]] — hub: the three model levels, platform layers, reference patterns, table formats, serving-layer modelling, and how decisions get recorded.
- [[concepts/ontology_layer|Ontology Layer]] — the formal domain vocabulary: classes, properties, axioms, and why inference separates it from a schema.
- [[concepts/semantic_layer|Semantic Layer]] — the governed translation tier between warehouse models and consumers: entities, metrics, grain, access rules.
- [[concepts/semantic_layer_vs_ontology_layer|Semantic Layer vs. Ontology Layer]] — measurement contract vs. vocabulary contract, how the two compose, and which to reach for.

## Databases

- [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the four guarantees, the mechanism behind each, and where they break down once distributed.
- [[concepts/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]] — session guarantees, tunable quorums, conflict resolution, and what BASE hands to the application.
- [[concepts/cap_theorem|CAP Theorem]] — what C, A, and P actually mean, why "pick two" is wrong, and the PACELC refinement.
- [[concepts/isolation_levels|Transaction Isolation Levels]] — the six anomalies with worked interleavings, the level matrix, and what each engine's level names really mean.

## Data Engineering

- [[concepts/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]] — per-job cost attribution from `INFORMATION_SCHEMA`, plus the controls those measurements justify.

### dbt (Data Build Tool)

- [[concepts/dbt|dbt (Data Build Tool)]] — models, `ref()`/`source()`, tests, macros, materializations, project layering, governance features, Core vs. Cloud.
- [[concepts/dbt_bigquery_adapter|dbt-bigquery Adapter]] — `profiles.yml` parameters, all four auth methods, BigQuery model configs, incremental strategies, cost control.
- [[concepts/dbt_databricks_adapter|dbt-databricks Adapter]] — `profiles.yml` parameters, PAT and OAuth M2M/U2M flows, multiple compute targets, common connection failures.
- [[concepts/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]] — a worked template: Dockerfile, Workload Identity, both workflows, state deferral, scheduling.

## Software Engineering

- [[concepts/software_architecture|Software Architecture]] — hub: quality attributes, architectural styles and their costs, decomposition, cross-cutting decisions, ADRs and C4.
- [[concepts/api_integration_protocols|API and Integration Protocols]] — REST, GraphQL, gRPC, SOAP, webhooks, SSE, WebSockets, MQTT, AMQP, and EDI, organized by interaction style.
- [[concepts/brainboard|Brainboard]] — tool overview: visual multi-cloud design that generates Terraform/OpenTofu, with embedded CI/CD, drift detection, and policy and cost scanning. Vendor-sourced, unverified.
- [[concepts/concurrency_and_parallelism|Concurrency and Parallelism]] — threads vs. processes vs. the event loop, I/O- against CPU-bound workloads, race conditions with worked interleavings, and the synchronization primitives and deadlock conditions.
- [[concepts/fix_protocol|FIX Protocol (Financial Information eXchange)]] — session vs. application layer, the order lifecycle, versions and encodings, and its ingestion pitfalls.
- [[concepts/global_interpreter_lock|Global Interpreter Lock (GIL)]] — why CPython serializes bytecode, when the lock is released, what it costs, and the four ways around it including free-threaded builds.
- [[concepts/semantic_versioning|Semantic Versioning (SemVer)]] — the increment rules, precedence algorithm, pre-release suffixes, and how it surfaces in data tooling.
- [[concepts/trivy|Trivy]] — tool overview: one open-source scanner for CVEs, IaC misconfiguration, secrets and licences across images, repos, clusters and SBOMs, and where the CI gate belongs.

## Data Structures and Algorithms

- [[concepts/data_structures_algorithms|Data Structures and Algorithms]] — hub: the read/write/space trade-off that separates the structures below.
- [[concepts/b_plus_tree|B+ Tree]] — all records in chained leaves; the index structure shipped by virtually every relational database.
- [[concepts/b_tree|B-Tree]] — the baseline disk-oriented balanced tree every other index structure is compared against.
- [[concepts/bloom_filter|Bloom Filter]] — probabilistic set membership: no false negatives, tunable false positives, and the sizing formulas.
- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — write-optimized storage: memtable, SSTables, compaction, and the read amplification it trades for.
- [[concepts/trie|Trie (Prefix Tree)]] — prefix-keyed retrieval, when position-in-string beats comparison, and the compressed variants.
