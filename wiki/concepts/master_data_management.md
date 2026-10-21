---
title: Master Data Management (MDM)
tags: [data-governance, master-data, entity-resolution]
created: 2026-09-22 09:11:46
updated: 2026-10-21 14:23:04
---

# Master Data Management (MDM)

Master Data Management is the discipline of producing and maintaining a single authoritative version of the business's core entities — customer, product, supplier, location, employee — across systems that each hold their own partial, conflicting copy. It is the part of [[concepts/data_governance|Data Governance]] that deals with the *data itself* rather than policy about it, and it exists because the same customer is `C-1047` in the CRM, `ACME CORP.` in billing, and `Acme Corporation` in the support desk.

## Why It Matters

- **Duplicate entities corrupt every aggregate downstream.** If one customer appears three times, customer counts, lifetime value, churn rates, and segment sizes are all wrong — and no dashboard will reveal it.
- **Integration cost compounds.** Without a shared identifier, every new system-to-system connection needs its own bespoke mapping. $n$ systems need $O(n^2)$ mappings; a master hub makes it $O(n)$.
- **Regulation assumes you can find a person.** "Delete everything you hold about me" is unanswerable if you cannot determine which records are the same person.
- **It is a prerequisite, not a deliverable.** A [[concepts/semantic_layer|Semantic Layer]] that aggregates over unresolved entities produces confidently wrong metrics.

## The Four Kinds of Data

MDM is defined by what it is *not*, so the distinction matters:

| Kind | Changes | Volume | Example |
| --- | --- | --- | --- |
| **Master** | Slowly | Low | Customer, product, supplier, location |
| **Reference** | Rarely, often externally governed | Very low | Country codes, currencies, chart of accounts, ISO industry codes |
| **Transactional** | Constantly | High | Orders, payments, shipments, clicks |
| **Metadata** | On schema change | Low | Column descriptions, lineage — see [[concepts/metadata_management|Metadata Management]] |

Transactional records *reference* master data; they are not master data. Reference data is often managed by the same program but is simpler: it is usually a controlled list to be distributed, not a matching problem.

## The Golden Record

The golden record is the reconciled, best-known version of an entity, assembled from every contributing source. Two mechanisms produce it.

### Entity Resolution (Matching)

Deciding which records refer to the same real-world thing.

- **Deterministic matching** compares exact or rule-normalized values — same tax ID, or same normalized email. Fast, explainable, and brittle: it misses `Bob` vs. `Robert` and anything with a typo.
- **Probabilistic matching** scores a weighted similarity across many attributes (name, address, date of birth) and compares the score to thresholds. It catches fuzzy duplicates at the cost of explainability and tuning effort.
- **Blocking** is the practical necessity underneath both: comparing every record to every other is $O(n^2)$ and infeasible at scale, so records are first bucketed by a cheap key (postcode, name prefix, phonetic code such as Soundex or Metaphone) and compared only within a bucket. Prefix structures like the [[concepts/trie|Trie (Prefix Tree)]] and edit-distance traversals over them are the classic implementation.

Probabilistic matching produces three outcomes, and the middle one is where the work is:

| Score band | Action |
| --- | --- |
| Above the auto-merge threshold | Merge automatically |
| Between the thresholds | **Queue for a human steward** |
| Below the auto-reject threshold | Treat as distinct |

Tuning those thresholds is a business decision, not a technical one. A false merge (two real customers collapsed into one) is usually far more damaging and much harder to undo than a false split.

### Survivorship (Merging)

Once records are matched, survivorship rules decide which value wins per attribute. Common strategies: most recent update, most trusted source system, most complete, most frequent across sources, or an explicit steward override. Survivorship is **per attribute, not per record** — the best address and the best phone number often come from different systems.

> [!important] Keep the cross-reference, always
> The golden record must retain the source-system keys that contributed to it. Without that cross-reference table, you cannot explain a value's origin, cannot push the golden value back to source systems, and cannot unmerge when a merge turns out to be wrong. Unmerge capability is not optional.

## Implementation Styles

| Style | How it works | Source systems | Good for | Cost |
| --- | --- | --- | --- | --- |
| **Registry** | Hub stores only keys and the cross-reference; golden record assembled virtually on read | Unchanged | Analytics, fast start, low political cost | No operational cleanup; read-time assembly |
| **Consolidation** | Copies flow into a hub, matched and merged there; hub feeds the warehouse | Unchanged, stay authoritative | Reporting and a trusted analytical view | Golden record is downstream-only |
| **Coexistence** | Like consolidation, but cleansed values are published *back* to source systems | Updated by the hub | Gradual improvement without replacing systems | Bidirectional sync complexity |
| **Centralized (transaction)** | The hub *is* the system of record; applications read and write it directly | Subordinate | Highest data quality, strongest control | Most invasive and most expensive |

Programs typically start at registry or consolidation and move rightward. Attempting centralized MDM as a first step is the most common way these projects fail: it requires changing applications the MDM team does not own.

## Hierarchies

Master data is rarely flat. A product rolls up to a category and a brand; a customer belongs to a legal entity that belongs to a corporate group; a location nests into region and country. Hierarchy management is frequently underestimated:

- The same entities support **multiple alternate hierarchies** — a sales hierarchy and a finance hierarchy over the same products will differ, and both are legitimate.
- Hierarchies are **time-variant**. Reorganizations mean last year's numbers must sometimes roll up the old way and sometimes be restated; you must decide which, explicitly.
- They are **ragged and unbalanced** in practice, which breaks naive parent-child reporting assumptions.

## Operating the Practice

1. **Start with one domain and one pain.** "Customer, because marketing is mailing people three times" beats an enterprise programme covering six domains.
2. **Define the entity before matching it.** What *is* a customer — an individual, a household, a billing account, a legal entity? Most matching arguments are really definition arguments, and the answer belongs in the business glossary.
3. **Profile before you build rules.** Measure how bad the duplication actually is; the result usually reorders your priorities.
4. **Staff the exception queue.** Probabilistic matching *will* produce ambiguous pairs forever. An MDM system without stewards working its queue degrades into an unmaintained one — see [[concepts/data_stewardship|Data Stewardship]].
5. **Fix upstream where possible.** Validation at the point of entry prevents duplicates far more cheaply than matching them afterwards. Matching is remediation; prevention is cheaper.
6. **Publish the golden record where it gets used.** Conformed dimensions materialized as [[concepts/dbt|dbt (Data Build Tool)]] marts are the usual analytical delivery path.

**Useful metrics:** estimated duplicate rate per domain, auto-match rate vs. manual queue volume, steward queue age, false-merge incidents, completeness of key attributes on golden records, and adoption (how many consumers actually use the golden key).

## Common Pitfalls

- **Treating it as a technology project.** The hard problems are definitional and political — who owns "customer" — and no tool resolves them.
- **Boiling the ocean.** Multi-domain, multi-year programmes lose sponsorship before delivering value.
- **Tuning for auto-merge rate.** A high merge rate looks efficient and quietly destroys distinct entities. False merges are the expensive error.
- **No unmerge path.** Discovering that two real companies were collapsed, with no way to separate them, is a genuine data-loss event.
- **Ignoring reference data.** It is the easy half of the problem and often delivers value fastest.
- **Letting the hub drift.** A golden record that is not continuously refreshed from sources becomes a fourth conflicting copy rather than the resolution of the other three.

## Related Concepts

- [[concepts/data_governance|Data Governance]] — supplies the ownership and decision rights that make entity definitions settleable
- [[concepts/data_stewardship|Data Stewardship]] — stewards resolve the match/merge exceptions the algorithms cannot decide
- [[concepts/data_quality|Data Quality]] — uniqueness and consistency are the dimensions MDM directly attacks; profiling is how the case gets made
- [[concepts/metadata_management|Metadata Management]] — governs the description of data; MDM governs the business data itself, and the glossary is where entity definitions live
- [[concepts/ontology_layer|Ontology Layer]] — declares the classes that MDM resolves real records into
- [[concepts/semantic_layer|Semantic Layer]] — aggregates over the entity identities MDM establishes; unresolved duplicates become wrong metrics
- [[concepts/trie|Trie (Prefix Tree)]] — the structure behind blocking keys and fuzzy name matching at scale
- [[concepts/dbt|dbt (Data Build Tool)]] — conformed dimensions built on golden records are typically materialized as marts
