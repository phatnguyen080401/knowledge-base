---
title: Semantic Layer vs. Ontology Layer
tags: [data-architecture, data-modeling, metric-definition, knowledge-graph, comparison]
created: 2026-09-29 15:42:29
updated: 2026-10-21 14:23:04
---

# Semantic Layer vs. Ontology Layer

A [[concepts/data_architecture/semantic_layer|Semantic Layer]] and an [[concepts/data_architecture/ontology_layer|Ontology Layer]] are
routinely conflated because both claim to hold "business meaning", but they answer different
questions: the semantic layer answers *what is the number and how is it computed*, the ontology
layer answers *what exists and how is it related*. This note is the side-by-side comparison; each
layer is described in full in its own note.

## The Core Distinction

The semantic layer is a **measurement contract**. It exists so that "revenue" resolves to one
agreed calculation no matter who asks, and its output is a number.

The ontology layer is a **vocabulary contract**. It exists so that "Customer" means the same thing
in the CRM, the billing system, and the warehouse, and its output is a shared, inspectable model of
the domain.

Neither subsumes the other. You can have a perfectly consistent revenue metric computed over
entities nobody has formally defined, and you can have a rigorous ontology with no agreed metrics
over it.

## Comparison

| | Semantic Layer | Ontology Layer |
| --- | --- | --- |
| **Question answered** | "What is the number, and how is it computed?" | "What exists, and how is it related?" |
| **Primary unit** | Metric, dimension, entity mapping | Class, property, relationship, axiom |
| **Formalism** | SQL-generating models (YAML, LookML, MDX) | Graph models (RDF/OWL, property graph, labelled schema) |
| **Purpose** | Consistent, governed measurement | Shared meaning and machine inference |
| **Scope** | Usually one analytical estate | Cross-domain, spans operational and analytical systems |
| **Reasoning** | Aggregation and filtering only | Inheritance, transitivity, inferred facts, constraint checking |
| **Runtime** | Compiles to SQL, executes on the warehouse | Traversed/queried (SPARQL, Cypher, GQL) or used as a mapping contract |
| **Fails by** | Metric sprawl, wrong grain, runaway query cost | Over-modeling, unmaintained drift, unusable formality |
| **Typical owner** | Analytics engineering | Data architecture, with domain stewards |

## How They Compose

They are complementary, not competing, and the usual arrangement stacks them:

1. The **ontology** declares that a `Customer` exists, that it has `placed` `Order`s, and that a
   `Subscription` is a kind of `Contract`.
2. [[concepts/data_governance/master_data_management|Master Data Management (MDM)]] resolves the actual records in
   each source system onto those declared entities.
3. The **semantic layer** defines `Customer Lifetime Value` as an aggregation over the orders
   belonging to a resolved customer, and compiles that definition to SQL on request.

The ontology is the upstream vocabulary; the semantic layer is the downstream calculator. Where an
organization has only one, it is almost always the semantic layer — it pays off sooner and needs
less coordination.

## Choosing Between Them

Reach for a **semantic layer** when the pain is disagreeing dashboards, duplicated metric SQL, or
LLM agents inventing their own aggregations. It is the cheaper and more immediately valuable of the
two for an analytics-only estate.

Reach for an **ontology layer** when the pain is cross-system integration — the same entity named
five ways, relationships that must be traversed rather than joined, or a need to infer and validate
facts rather than just aggregate them.

The failure mode in both directions is using one where you need the other: modeling deep
relationships as semantic-layer dimensions produces an unmaintainable star schema, and encoding
aggregations as ontology properties mixes measurement into the vocabulary and makes both harder to
change.

## Related Concepts

- [[concepts/data_architecture/semantic_layer|Semantic Layer]] — the measurement side of the comparison, in full
- [[concepts/data_architecture/ontology_layer|Ontology Layer]] — the vocabulary side of the comparison, in full
- [[concepts/data_governance/master_data_management|Master Data Management (MDM)]] — the resolution step that connects ontology classes to real records the semantic layer aggregates
- [[concepts/data_architecture/data_architecture|Data Architecture]] — the structure both layers sit within
- [[concepts/data_governance/metadata_management|Metadata Management]] — where either layer's definitions are catalogued and versioned
