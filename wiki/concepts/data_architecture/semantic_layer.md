---
title: Semantic Layer
tags: [data-architecture, data-modeling, metric-definition]
created: 2026-09-29 15:39:23
updated: 2026-10-26 18:00:17
---

# Semantic Layer

A semantic layer is a governed translation tier that maps physical tables and columns onto
business-friendly entities, dimensions, and metrics, so that every consumer — BI tool, notebook,
or AI agent — resolves the same question to the same number. It sits between the warehouse
modeled under [[concepts/data_architecture/data_architecture|Data Architecture]] and the tools that query it.

## Why It Matters

Without a semantic layer, each dashboard re-implements `revenue` in its own SQL. Definitions drift,
two reports disagree, and nobody can say which is right. Centralizing the definition makes the
metric a versioned artifact rather than a convention, which is the same accountability argument
that drives [[concepts/data_governance/data_governance|Data Governance]].

## What It Contains

- **Entities** — the business objects (customer, order, subscription) and the tables that back them.
- **Dimensions** — the attributes a metric can be sliced by, plus their allowed hierarchies.
- **Metrics** — named measures with an explicit aggregation, filter, and grain.
- **Joins and grain rules** — how entities relate, so the engine can fan-out-safely aggregate.
- **Access policy** — row- and column-level rules enforced at query time, tying into
  [[concepts/data_governance/data_security|Data Security]].

## How It Executes

A semantic layer is a **query compiler**, not a store. A request such as
"revenue by region, last quarter" is compiled to SQL against the warehouse and executed there.
Two deployment styles exist:

| Style             | Where definitions live                               | Example                   |
| ----------------- | ---------------------------------------------------- | ------------------------- |
| **Tool-embedded** | Inside the BI tool's own model                       | Power BI, Tableau, Looker |
| **Headless**      | Version-controlled, served over an API to any client | dbt Semantic Layer, Cube  |

Headless is the direction of travel, because it is the only one that also serves notebooks and
LLM-driven agents — routing an agent here instead of letting it author its own SQL is the
grounding decision an [[concepts/ai_engineering/ai_engineer|AI Engineer]] makes first. In
[[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] the definitions live beside the models
as YAML and inherit the same tests, lineage, and CI.

## Semantic Layer vs. Ontology Layer

The two are routinely conflated because both claim to hold "business meaning", but the semantic
layer answers *what is the number and how is it computed* while an
[[concepts/data_architecture/ontology_layer|Ontology Layer]] answers *what exists and how is it related*. They are
complementary: an ontology defines what a "Customer" *is* across CRM, billing, and support, and the
semantic layer defines how "Customer Lifetime Value" is *measured* over those entities. See
[[concepts/data_architecture/semantic_layer_vs_ontology_layer|Semantic Layer vs. Ontology Layer]] for the full
side-by-side.

## Pitfalls

- **Metric sprawl** — allowing ad-hoc metric definitions alongside the layer defeats its purpose.
- **Grain errors** — joining a daily-grain fact to a monthly-grain fact fans out rows and silently
  inflates totals; the layer must encode grain, not assume it.
- **Performance surprise** — compiled SQL can be far more expensive than hand-written SQL; caching
  and pre-aggregation are part of the design, not an afterthought.
- **Treating it as an ontology** — modeling deep relationships as dimensions produces an
  unmaintainable star schema. If you need inference, you need an ontology.

## Related Concepts

- [[concepts/data_architecture/ontology_layer|Ontology Layer]] — the formal model of what exists, which the semantic layer measures over
- [[concepts/data_architecture/semantic_layer_vs_ontology_layer|Semantic Layer vs. Ontology Layer]] — the side-by-side comparison and guidance on which one a given problem calls for
- [[concepts/data_governance/metadata_management|Metadata Management]] — where metric definitions and their lineage are catalogued
- [[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] — a common home for headless semantic-layer definitions
- [[concepts/data_governance/data_governance|Data Governance]] — supplies the ownership and approval process for a metric definition
- [[concepts/data_governance/master_data_management|Master Data Management (MDM)]] — resolves the entity identities the semantic layer aggregates over
- [[concepts/ai_engineering/ai_engineer|AI Engineer]] — the consumer that most needs a governed metric: an agent asked for revenue should look it up, not compute it
