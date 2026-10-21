---
title: Ontology Layer
tags: [data-architecture, data-modeling]
created: 2026-09-29 15:39:23
updated: 2026-10-21 14:23:04
---

# Ontology Layer

An ontology layer is a formal, machine-readable model of the concepts in a domain — their classes,
attributes, relationships, and the rules constraining them — used to give every system a shared
vocabulary independent of any one database schema. It is the meaning tier of a
[[concepts/data_architecture|Data Architecture]].

## Why It Matters

Schemas encode meaning implicitly and inconsistently: `cust_id`, `customer_number`, and `party_ref`
may denote the same thing across three systems, and only tribal knowledge says so. An ontology
states that identity explicitly and in a form a machine can act on, which is what makes automated
integration, reasoning, and reliable LLM grounding possible.

## Core Constructs

- **Classes** — the kinds of thing that exist (`Customer`, `Product`, `Contract`).
- **Properties** — attributes of a class, and relationships between classes
  (`Customer —placed→ Order`).
- **Hierarchy** — subclass and subproperty relations, giving inheritance.
- **Axioms and constraints** — rules such as cardinality, disjointness, domain and range, or
  transitivity, which a reasoner can enforce and use to infer new facts.
- **Identifiers** — stable URIs or keys so the same entity is recognizable across systems.

## Formalisms

| Approach | Typical use |
| --- | --- |
| **RDF / RDFS / OWL** | Standards-based, strongest inference, interoperable across organizations |
| **Property graph schema** | Pragmatic; models relationships without full OWL reasoning |
| **Vendor semantic/ontology models** | Bound to one platform's object layer, easier to adopt, harder to port |
| **Taxonomy / controlled vocabulary** | The lightest form — classification only, no relationships or axioms |

A taxonomy is not an ontology: a taxonomy classifies, an ontology also relates and constrains.

## Inference

The property that distinguishes an ontology from a schema is that facts can be *derived* rather
than only stored. Given `subsidiaryOf` declared transitive, asserting `A subsidiaryOf B` and
`B subsidiaryOf C` yields `A subsidiaryOf C` without anyone writing that row. The same machinery
detects contradictions, which turns the ontology into a validation surface as well as a vocabulary.

## Where It Sits

The ontology is upstream of measurement. It names and relates the things;
[[concepts/semantic_layer|Semantic Layer]] defines how those things are counted and aggregated for
reporting. Ontology classes also give [[concepts/master_data_management|Master Data Management (MDM)]]
its target model — entity resolution is the act of deciding which records denote the same
ontology individual.

## Pitfalls

- **Boiling the ocean** — enterprise-wide ontologies modeled up front rarely ship; grow them per
  domain against a real integration need.
- **Over-formalization** — full OWL reasoning is expensive and often unnecessary when a constrained
  property graph would do.
- **No ownership** — an ontology with no steward rots faster than a schema, because nothing breaks
  loudly when it drifts.
- **Duplicating the semantic layer** — encoding aggregations and metrics as ontology properties
  mixes measurement into the vocabulary and makes both harder to change.

## Related Concepts

- [[concepts/semantic_layer|Semantic Layer]] — the measurement tier built over the entities the ontology defines
- [[concepts/semantic_layer_vs_ontology_layer|Semantic Layer vs. Ontology Layer]] — the side-by-side comparison and guidance on which one a given problem calls for
- [[concepts/metadata_management|Metadata Management]] — the catalog where an ontology is published and versioned
- [[concepts/master_data_management|Master Data Management (MDM)]] — resolves real records to the entities the ontology declares
- [[concepts/data_stewardship|Data Stewardship]] — supplies the owner accountable for each class definition
- [[concepts/data_architecture|Data Architecture]] — the structural design the ontology gives shared meaning to
