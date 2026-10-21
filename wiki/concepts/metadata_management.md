---
title: Metadata Management
tags: [data-governance, metadata]
created: 2026-09-22 09:11:46
updated: 2026-10-21 11:22:46
---

# Metadata Management

Metadata management is the discipline of capturing, storing, and curating the descriptive context around data assets — what a field means, where it came from, who owns it, how fresh it is, and who may see it — so that data can be found, trusted, and used correctly. It is the connective tissue of [[concepts/data_governance|Data Governance]]: almost every other governance practice depends on metadata that someone bothered to capture.

## Why It Matters

- **Discovery.** In a warehouse with ten thousand tables, a dataset nobody can find is a dataset nobody uses. Search over metadata is the only practical entry point.
- **Trust.** A number is only as credible as its provenance. Lineage and ownership are what let an analyst decide whether to use a table or escalate it.
- **Impact analysis.** "If I drop this column, what breaks?" is a lineage query. Without it, every schema change is a gamble.
- **Governance enforcement.** Classification tags drive masking policies, retention schedules, and access rules — see [[concepts/data_security|Data Security]]. Untagged data cannot be governed automatically.
- **It decays silently.** Unlike a broken pipeline, stale metadata raises no alert. It simply misleads people until someone notices.

## The Four Types of Metadata

| Type | Answers | Typical examples | Usually captured by |
| --- | --- | --- | --- |
| **Technical** | What is it, physically? | Schemas, data types, partitioning, row counts, file formats, indexes | Automated crawlers |
| **Business** | What does it mean? | Glossary terms, definitions, calculation rules, ownership, classification | Humans — stewards |
| **Operational** | What happened to it? | Job run times, row counts per load, freshness, failures, query history and cost | Pipeline and platform logs |
| **Social** | How is it actually used? | Popularity, top queries, ratings, certification badges, Q&A threads | Platform usage telemetry |

Technical and operational metadata are nearly free — the platform emits them. Business metadata is expensive because it requires human judgement, which is why it is the facet most programs under-invest in and the one that matters most to a confused analyst.

## Glossary, Dictionary, Catalog — Three Different Things

These are routinely conflated, and the distinction is worth holding:

- **Business glossary** — the organization's agreed vocabulary. One entry per *business concept*: "Active Customer", "Net Revenue". Owned by the business, independent of any system. The glossary is where "what counts as active?" is settled once.
- **Data dictionary** — the field-level description of a *specific* dataset: column names, types, nullability, allowed values, and which glossary term each column implements.
- **Data catalog** — the searchable inventory and the tool that ties the other two together, adding lineage, ownership, usage, and classification across every system.

A mature setup links them: a glossary term maps to many dictionary entries, which belong to catalogued assets. When this mapping exists, "which tables contain Net Revenue?" becomes answerable, and the formal version of that vocabulary is an [[concepts/ontology_layer|Ontology Layer]].

## Data Lineage

Lineage is the directed graph of how data moves and transforms from source to consumption.

**Granularity:**

- **Table-level** — "`fct_orders` is built from `stg_orders` and `stg_customers`." Cheap, and enough for most impact analysis.
- **Column-level** — "`fct_orders.net_revenue` derives from `stg_orders.gross` minus `stg_orders.discount`." Far more useful and far harder; requires parsing SQL rather than reading job configs.

**How it gets captured:**

| Method | How it works | Strength | Weakness |
| --- | --- | --- | --- |
| **Parse-based** | Static analysis of SQL and transformation code | Complete, no runtime needed | Breaks on dynamic SQL and stored procedures |
| **Runtime** | Query logs and execution plans from the engine | Reflects what actually ran | Misses paths that have not run yet |
| **Framework-emitted** | The tool declares its own graph (dbt, Airflow, Spark) | Accurate and cheap | Only covers assets inside that tool |
| **Manual** | Stewards document it | Covers anything | Stale almost immediately |

Real programs combine them, and the hard part is stitching the pieces into one graph across tools. **The gap is almost always at the edges** — a CSV emailed to finance, a spreadsheet, a BI tool's internal calculation. Lineage that stops at the warehouse boundary will understate impact.

> [!warning] Lineage is not a free byproduct
> Tools advertise "automatic lineage", but coverage is a function of what they can parse. Anything crossing a tool boundary, a reverse-ETL hop, or a hand-run script is invisible unless someone wires it in.

## Active vs. Passive Metadata

The distinction that separates a useful catalog from a dead wiki:

- **Passive metadata** sits in a catalog waiting to be read. Humans must go look at it, so they mostly don't.
- **Active metadata** is fed back into systems to *do* something: a classification tag that automatically applies a masking policy, a freshness SLA that fires an alert, a lineage edge that blocks a breaking deploy, a cost signal that recommends a partition key.

A catalog nobody opens still pays for itself if its metadata drives policy. This is the strongest argument for investing in classification over documentation.

## Where Metadata Comes From

- **Transformation frameworks.** [[concepts/dbt|dbt (Data Build Tool)]] produces `manifest.json` and `catalog.json` on every run — model graph, column descriptions, tests, and freshness — which is the cheapest high-quality technical metadata most teams can get. Its `persist_docs` setting pushes descriptions down into the warehouse itself.
- **The warehouse's own views.** `INFORMATION_SCHEMA` and its equivalents carry schemas, partitioning, and job history; see [[concepts/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]] for the operational slice of that metadata used for cost attribution.
- **Schema registries.** For streaming and APIs, the registry holds the contract and enforces compatibility on write — a producer cannot publish an incompatible schema. This is metadata with teeth, and it pairs with [[concepts/semantic_versioning|Semantic Versioning (SemVer)]] for how versions are numbered.
- **Protocol dictionaries.** Some formats are uninterpretable without governed metadata: the [[concepts/fix_protocol|FIX Protocol (Financial Information eXchange)]] tag dictionary and per-counterparty rules of engagement are a hard example — the same tag number means different things in different dialects.
- **Orchestrators and BI tools**, for run history and downstream usage.

## Operating the Practice

1. **Start from a question, not an inventory.** "Which tables hold PII?" or "what breaks if this column changes?" scopes the work. "Catalog everything" does not finish.
2. **Automate the technical facet entirely.** Hand-maintained schema documentation is stale on arrival.
3. **Assign ownership before descriptions.** An asset with a named owner can be fixed later; an orphaned asset with a nice description cannot. Owners come from [[concepts/data_stewardship|Data Stewardship]].
4. **Prioritize by usage.** Document the top 5% of assets by query volume first; the long tail may never deserve attention.
5. **Certify and deprecate.** A trust signal on the asset is worth more than a paragraph of prose. Deprecation badges steer people off dying tables.
6. **Put curation in the workflow.** Descriptions written in the transformation repo alongside the model, and reviewed in the same pull request, survive. Descriptions typed into a catalog UI drift away from the code.

**Useful metrics:** percentage of high-usage assets with an owner and a description, glossary-term coverage, lineage coverage (what fraction of assets have upstream edges), classification coverage, and time-to-find in user surveys.

## Common Pitfalls

- **Cataloguing everything at once.** The effort is enormous and the result is a sea of empty descriptions that teaches users the catalog is useless.
- **Buying a tool instead of adopting a practice.** A catalog with no stewards is an expensive empty database.
- **Documentation divorced from code.** If the description lives only in the catalog UI, it will contradict the model within a quarter.
- **Table-level lineage mistaken for column-level.** It will tell you a table is affected, not whether the specific column you care about is.
- **Treating the glossary as a dictionary.** Hundreds of entries that merely restate column names, and no agreement on the dozen definitions that are actually contested.
- **No deprecation path.** Catalogs accumulate; without a retirement process, search results degrade over time.

## Related Concepts

- [[concepts/data_governance|Data Governance]] — the parent discipline; metadata is the substrate its policies are written against
- [[concepts/data_stewardship|Data Stewardship]] — the humans who curate business metadata; without them only the automated facets get populated
- [[concepts/data_quality|Data Quality]] — quality rules are metadata, and their results become operational metadata on the asset
- [[concepts/master_data_management|Master Data Management (MDM)]] — MDM governs the business data itself; metadata management governs the description of it
- [[concepts/ontology_layer|Ontology Layer]] — the formal, machine-reasonable version of the business glossary
- [[concepts/semantic_layer|Semantic Layer]] — metric definitions are high-value business metadata, and the catalog is where their lineage is published
- [[concepts/data_security|Data Security]] — classification metadata is what drives masking, retention, and access policy automatically
- [[concepts/dbt|dbt (Data Build Tool)]] — `manifest.json` and `catalog.json` are the richest technical metadata source in a typical warehouse stack
