# Index

Every page in `wiki/concepts/`, grouped by domain. Read this first when answering a question —
shortlist from the summaries here, then open only the pages you need.

## Data Governance

- [[concepts/data_governance|Data Governance]] — the operating model for data: principles, roles, frameworks, and the pillars it coordinates.
- [[concepts/data_quality|Data Quality]] — the six dimensions and their checks, where defects originate, and the measure-remediate lifecycle.
- [[concepts/data_security|Data Security]] — protecting data from unauthorized access, disclosure, and alteration. **Stub.**
- [[concepts/data_stewardship|Data Stewardship]] — who is accountable: steward vs. owner vs. custodian, operating models, workflows, and metrics.
- [[concepts/master_data_management|Master Data Management (MDM)]] — golden records for the business's critical entities. **Stub.**
- [[concepts/metadata_management|Metadata Management]] — the glossary, dictionary, catalog, and lineage that give data assets context. **Stub.**

## Data Architecture

- [[concepts/data_architecture|Data Architecture]] — the rules, models, and standards governing how data is collected, stored, and integrated. **Stub.**
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
- [[concepts/fix_protocol|FIX Protocol (Financial Information eXchange)]] — session vs. application layer, the order lifecycle, versions and encodings, and its ingestion pitfalls.
- [[concepts/semantic_versioning|Semantic Versioning (SemVer)]] — the increment rules, precedence algorithm, pre-release suffixes, and how it surfaces in data tooling.

## Data Structures and Algorithms

- [[concepts/data_structures_algorithms|Data Structures and Algorithms]] — hub: the read/write/space trade-off that separates the structures below.
- [[concepts/b_plus_tree|B+ Tree]] — all records in chained leaves; the index structure shipped by virtually every relational database.
- [[concepts/b_tree|B-Tree]] — the baseline disk-oriented balanced tree every other index structure is compared against.
- [[concepts/bloom_filter|Bloom Filter]] — probabilistic set membership: no false negatives, tunable false positives, and the sizing formulas.
- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — write-optimized storage: memtable, SSTables, compaction, and the read amplification it trades for.
- [[concepts/trie|Trie (Prefix Tree)]] — prefix-keyed retrieval, when position-in-string beats comparison, and the compressed variants.
