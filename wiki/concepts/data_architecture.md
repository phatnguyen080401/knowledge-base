---
title: Data Architecture
tags: [data-architecture, data-modeling, architecture-patterns, overview]
created: 2026-09-22 09:11:46
updated: 2026-10-21 14:23:04
---

# Data Architecture

Data architecture is the structural design of how an organization's data is modelled, stored, moved, served, and governed — the set of decisions about layering, interfaces, storage technology, and ownership that everything else in the data platform inherits. It is the data-side counterpart of [[concepts/software_architecture|Software Architecture]], and like it, the defining characteristic of an architectural decision is that reversing it is expensive.

## Why It Matters

- **Its decisions are sticky.** Table formats, partitioning schemes, and ownership boundaries are cheap to choose and expensive to change once petabytes and hundreds of consumers depend on them.
- **It fixes the performance and cost envelope.** The physical layout chosen at design time determines what queries are possible at acceptable cost, long before anyone writes SQL.
- **It determines whether governance is feasible.** A platform with no serving boundary cannot enforce [[concepts/data_security|Data Security]] policy consistently, no matter how good the policy is.
- **Most "data quality problems" are architecture problems.** Duplicated pipelines, undefined ownership, and no single serving layer produce contradictory numbers far more often than bad source data does.

## The Three Levels of Model

A long-standing distinction that keeps architecture conversations from talking past each other:

| Level | Describes | Independent of | Audience |
| --- | --- | --- | --- |
| **Conceptual** | The entities and relationships the business cares about | Any technology | Business stakeholders |
| **Logical** | Attributes, keys, cardinality, normalization | Any specific engine | Architects and analysts |
| **Physical** | Tables, types, partitioning, clustering, file layout | Nothing — engine-specific | Engineers |

Skipping the conceptual level is the usual reason two teams build incompatible models of "order": they never agreed what an order *is*. The formal, machine-readable version of the conceptual level is an [[concepts/ontology_layer|Ontology Layer]].

## The Layers of a Platform

Nearly every modern data platform decomposes into the same functional layers, whatever the branding:

1. **Sources** — operational databases, SaaS APIs, event streams, files, third-party feeds.
2. **Ingestion** — batch extracts, change data capture, streaming. The decision here is push vs. pull and batch vs. continuous.
3. **Storage** — object storage, warehouse-managed storage, or a table format over a lake.
4. **Transformation** — cleaning, conforming, modelling. Typically ELT in the warehouse; [[concepts/dbt|dbt (Data Build Tool)]] is the common implementation.
5. **Serving** — the governed interface consumers actually query: marts, a [[concepts/semantic_layer|Semantic Layer]], APIs, or feature stores.
6. **Consumption** — BI, notebooks, reverse ETL, ML training and inference, embedded analytics.

Cutting across all six: governance, security, observability, orchestration, and cost management. **These cross-cutting concerns are where architectures most often fail** — they are everyone's responsibility, which means they are nobody's, unless the architecture assigns them explicitly.

## Reference Patterns

| Pattern | Core idea | Best when | Main cost |
| --- | --- | --- | --- |
| **Data warehouse** | Schema-on-write, curated and modelled before loading | Stable, structured, heavily reported-on data | Slow to accommodate new or semi-structured sources |
| **Data lake** | Schema-on-read, raw files in object storage | Cheap retention, diverse formats, ML workloads | Degenerates into a swamp without governance |
| **Lakehouse** | Table format over object storage adding ACID, schema, and time travel | Wanting warehouse semantics at lake cost and openness | Younger ecosystem; more assembly required |
| **Data mesh** | Domain teams own and publish data as products; central platform supplies the paved road | Large orgs where a central team is the bottleneck | Organizational change, duplicated effort, needs real platform investment |
| **Hub and spoke** | Central conformed core feeding departmental marts | Strong central governance with local flexibility | Hub becomes a bottleneck |

These are not mutually exclusive, and the marketing distinction between lakehouse and modern warehouse has narrowed considerably as warehouses added open table formats and lakes added transactional guarantees.

### Layered Refinement

Independent of pattern, transformation is almost always staged — raw → cleaned/conformed → business-ready, marketed variously as bronze/silver/gold or staging/intermediate/marts. The value is that each layer has one job and one contract: raw is an immutable landing zone that can be replayed, the middle layer is where conforming and deduplication happen, and the top layer is the contract with consumers. See [[concepts/dbt|dbt (Data Build Tool)]] for how this maps onto project structure.

## Batch, Streaming, and the Hybrids

The ingestion cadence is an architectural decision because it propagates everywhere downstream.

- **Batch** is simpler, cheaper, easier to test and backfill, and correct for the vast majority of analytics. It remains the right default.
- **Streaming** is justified by genuine latency requirements — fraud detection, operational dashboards, real-time personalization — not by the desire for data to be "fresh".
- **Lambda architecture** runs batch and streaming paths in parallel and reconciles them, paying for two implementations of the same logic.
- **Kappa architecture** treats everything as a stream and reprocesses history through the same path, avoiding the duplication at the cost of a harder replay story.

> [!warning] Streaming's real cost is correctness, not throughput
> Late-arriving and out-of-order events, exactly-once semantics, and windowing turn straightforward aggregations into genuinely hard problems. Adopt streaming when latency demands it, not by default.

## Storage and Table Formats

- **File formats.** Columnar formats (Parquet, ORC) are standard for analytics: column pruning and compression mean scanning less. Row formats (Avro, JSON) suit streaming and record-at-a-time access.
- **Table formats.** Iceberg, Delta Lake, and Hudi add a metadata layer over files that provides atomic commits, schema evolution, time travel, and partition evolution — bringing [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] guarantees to object storage. This is the technical core of the lakehouse claim.
- **Physical layout** — partitioning and clustering — is the single highest-leverage performance and cost decision in a scan-priced warehouse, since it determines how much data a query must read. The underlying structures are covered in [[concepts/data_structures_algorithms|Data Structures and Algorithms]], and the cost consequences in [[concepts/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]].

## Modelling Approaches for the Serving Layer

| Approach | Structure | Strength | Weakness |
| --- | --- | --- | --- |
| **Dimensional (Kimball)** | Facts and conformed dimensions in star schemas | Intuitive for analysts, excellent BI performance | Restating history and late-arriving changes need care |
| **Normalized (Inmon)** | 3NF enterprise warehouse feeding marts | Integrity, minimal redundancy | Join-heavy; unapproachable for direct querying |
| **Data Vault** | Hubs, links, satellites | Auditable, insert-only, tolerant of source change | Verbose; requires a presentation layer on top |
| **Wide / One Big Table** | Pre-joined denormalized tables | Simple and fast on columnar engines | Storage duplication; update anomalies |

Dimensional modelling remains the default for the serving layer, often fed by a Data Vault or normalized core in regulated environments where auditability matters. Conformed dimensions depend on resolved entities, which is where [[concepts/master_data_management|Master Data Management (MDM)]] becomes a prerequisite rather than an enhancement.

## Distribution Constraints

Once the architecture spans more than one node or region, physics imposes limits that no design can evade. The [[concepts/cap_theorem|CAP Theorem]] governs the consistency-versus-availability choice during a partition, and its PACELC extension adds the latency-versus-consistency trade in normal operation. Analytical platforms typically accept eventual consistency ([[concepts/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]]) because a dashboard seconds out of date is harmless; operational data stores usually cannot.

## Making and Recording Decisions

1. **Start from consumption.** Work backwards from the questions that must be answered and their latency and concurrency requirements. Architectures designed forward from available sources produce lakes nobody queries.
2. **Enumerate the quality attributes and rank them.** Latency, cost, flexibility, auditability, and operational simplicity genuinely conflict; an unranked list means the trade gets made implicitly.
3. **Assign ownership per data product**, not per technology. Unowned datasets decay regardless of how well they were designed.
4. **Decide the contract at each boundary** — schema, freshness, and compatibility guarantees, versioned per [[concepts/semantic_versioning|Semantic Versioning (SemVer)]].
5. **Record decisions as ADRs.** Context, options considered, decision, consequences. The reasoning is what future maintainers need; the outcome alone is visible in the code.
6. **Prefer reversible choices.** Where a decision can be deferred cheaply, defer it.

## Common Pitfalls

- **Technology-first design.** Choosing the platform before articulating the requirements, then retrofitting the requirements to it.
- **No serving boundary.** Letting every consumer query raw or staging tables guarantees divergent definitions of the same metric and makes any later refactor impossible.
- **Governance deferred to phase two.** Classification, lineage, and ownership are vastly cheaper designed in than retrofitted — see [[concepts/metadata_management|Metadata Management]].
- **Mesh without a platform.** Distributing ownership without first providing self-service infrastructure yields duplicated, inconsistent effort rather than autonomy.
- **Ignoring cost as a design constraint.** In consumption-priced platforms, the physical layout *is* the budget.
- **One architecture for every workload.** ML feature access, sub-second operational lookups, and quarterly finance reporting have genuinely different requirements.

## Related Concepts

- [[concepts/data_governance|Data Governance]] — supplies the policies, ownership, and standards the architecture must make enforceable
- [[concepts/software_architecture|Software Architecture]] — the same structural discipline applied to software generally; its component boundaries decide who produces and owns which data
- [[concepts/api_integration_protocols|API and Integration Protocols]] — the interface and messaging choices that determine how systems in the architecture exchange data
- [[concepts/data_structures_algorithms|Data Structures and Algorithms]] — the storage and indexing structures underneath the architecture, which fix its performance envelope
- [[concepts/cap_theorem|CAP Theorem]] — the constraint that forces the consistency-versus-availability choice once the architecture spans more than one node
- [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the guarantees open table formats bring to object storage, and the basis of the lakehouse claim
- [[concepts/ontology_layer|Ontology Layer]] — the formal vocabulary that gives the architecture's entities shared meaning
- [[concepts/semantic_layer|Semantic Layer]] — the governed translation tier between the physical models and their consumers
- [[concepts/master_data_management|Master Data Management (MDM)]] — resolves the entity identities that conformed dimensions in the serving layer depend on
- [[concepts/dbt|dbt (Data Build Tool)]] — the common implementation of the transformation layer and its staging/intermediate/marts layering
