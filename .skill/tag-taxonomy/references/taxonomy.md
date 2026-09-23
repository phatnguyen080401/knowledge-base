# Tag Taxonomy — Controlled Vocabulary

The complete, authoritative list of tags an agent may assign in `wiki/concepts/` frontmatter.
Every **mandatory** tag must come from this file; adding an entry requires user approval
(see "Adding a New Tag" in `SKILL.md`).

**Mandatory set — every note, always:** exactly one `domain`, zero to two `topic`, zero or one
`lifecycle` — 1 to 4 tags total, written in that order.

**Optional user tags:** the user may add further tags of their own choosing after the mandatory set.
They do not need to appear in this file and do not count toward the 1–4 limit, but they must be
lowercase `kebab-case` and must not be a banned tag. Never add or remove one without the user
asking.

---

## Facet 1 — Domain (required, exactly one)

The field of practice the note belongs to.

| Tag                 | Use for                                                                       |
| ------------------- | ----------------------------------------------------------------------------- |
| `analytics`         | Reporting, BI, metrics, dashboards, analytical modeling                       |
| `data-architecture` | Structural design of data systems: platforms, storage, pipelines, topology    |
| `data-engineering`  | Building and operating pipelines, ingestion, transformation, orchestration    |
| `data-governance`   | Policy, ownership, accountability, standards, compliance over data            |
| `data-management`   | Day-to-day operational handling of data assets across their lifecycle         |
| `data-security`     | Protecting data: access control, encryption, privacy, threat mitigation       |

If two domains fit equally well, the note likely covers two concepts — split it (`AGENTS.md` §4.3).

## Facet 2 — Topic (optional, zero to two)

A specific subject within the domain. Add one only if it says something the domain tag does not.

| Tag              | Use for                                                            |
| ---------------- | ------------------------------------------------------------------ |
| `access-control` | Permissions, roles, RBAC/ABAC, authorization models                |
| `api-protocols`  | API styles and wire protocols: REST, GraphQL, gRPC, messaging, streaming |
| `cataloging`     | Data catalogs, discovery, asset inventories                        |
| `compliance`     | Regulatory obligations, audits, regulated-data handling            |
| `data-modeling`  | Conceptual, logical, and physical schema design                    |
| `data-quality`   | Accuracy, completeness, consistency, quality dimensions and rules  |
| `integration`    | Moving and reconciling data across systems, ETL/ELT, interop       |
| `lineage`        | Provenance, upstream/downstream tracing, impact analysis           |
| `master-data`    | Golden records, reference data, entity resolution, MDM             |
| `metadata`       | Descriptive, technical, and operational metadata                   |
| `privacy`        | PII, consent, anonymization, data subject rights                   |
| `stewardship`    | Steward and owner roles, accountability, operating models          |

## Facet 3 — Lifecycle (optional, zero or one)

State of the note itself, not its subject. Remove as soon as it stops being true.

| Tag            | Use for                                                                      |
| -------------- | ---------------------------------------------------------------------------- |
| `needs-review` | Content is unverified, thin in places, or conflicts with another page        |
| `stub`         | Placeholder — little more than a definition and a couple of links            |

---

## Banned Tags

**Never tag a note with a general, useless, arbitrary, ambiguous, or uninformative tag.** A tag
earns its place only if it tells a reader something the note's location, title, and other tags do
not already say. If a tag would apply to almost every note in the vault, or if you cannot state in
one sentence what it excludes, it is uninformative — leave it off.

This rule binds mandatory tags and optional user tags alike. If a user asks for a tag that fails it,
say so and propose a specific alternative before writing.

| Category                   | Never use                                                          | Why                                                     |
| -------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------- |
| Structural / already known | `concept`, `concepts`, `note`, `notes`, `page`, `wiki`, `vault`     | Encoded by the file's location in `wiki/concepts/`      |
| Universally true           | `data`, `datum`, `information`, `knowledge`, `topic`, `subject`     | Applies to every note; separates nothing                |
| Catch-all                  | `general`, `misc`, `miscellaneous`, `other`, `various`, `stuff`     | Names the absence of a category, not a category         |
| Vague quality / priority   | `important`, `useful`, `interesting`, `key`, `core`, `basic`, `advanced` | Subjective and unstable; means nothing to a later reader |
| Ambiguous                  | `model`, `system`, `process`, `management`, `type`, `level`         | Too many readings; pick the precise facet tag instead   |
| Workflow noise             | `todo`, `fixme`, `temp`, `test`, `untagged`, `new`, `old`           | Ephemeral; use `stub` or `needs-review`, or a real task |

The list is illustrative, not exhaustive — reject any tag matching the spirit of these categories,
including plurals, synonyms, and casing variants.

---

## Alias Map

Tags previously seen in this vault or commonly typed, and their canonical replacement.
When normalizing, rewrite the left side to the right side.

| Found tag       | Action                                                                  |
| --------------- | ----------------------------------------------------------------------- |
| `architecture`  | → `data-architecture`                                                   |
| `concept`       | remove (banned)                                                         |
| `concepts`      | remove (banned)                                                         |
| `data`          | remove (banned)                                                         |
| `dataquality`   | → `data-quality`                                                        |
| `data_quality`  | → `data-quality`                                                        |
| `general`       | remove (banned)                                                         |
| `governance`    | → `data-governance`                                                     |
| `important`     | remove (banned)                                                         |
| `mdm`           | → `master-data`                                                         |
| `misc`          | remove (banned)                                                         |
| `pii`           | → `privacy`                                                             |
| `quality`       | → `data-quality`                                                        |
| `security`      | → `data-security`                                                       |
| `steward`       | → `stewardship`                                                         |
| `todo`          | remove (banned)                                                         |
| `WIP`           | → `stub`                                                                |

Deduplicate after mapping: if an alias resolves to a tag the note already carries, drop the duplicate.
A removal must never empty the mandatory set — if it would, assign a proper facet tag in its place.

---

## Worked Examples

| Note                                 | Mandatory tags                                   | With optional user tags                                          |
| ------------------------------------ | ------------------------------------------------ | ---------------------------------------------------------------- |
| `api_integration_protocols.md`       | `[data-architecture, api-protocols]`             | —                                                                |
| `data_governance.md`                 | `[data-governance]`                              | `[data-governance, exam-prep]`                                   |
| `data_quality.md`                    | `[data-governance, data-quality]`                | `[data-governance, data-quality, dama-dmbok, exam-prep]`         |
| `data_stewardship.md`                | `[data-governance, stewardship]`                 | —                                                                |
| `metadata_management.md`             | `[data-management, metadata, cataloging]`        | —                                                                |
| `master_data_management.md`          | `[data-management, master-data]`                 | `[data-management, master-data, project-atlas]`                  |
| `data_architecture.md`               | `[data-architecture]`                            | —                                                                |
| `data_security.md`                   | `[data-security, access-control]`                | —                                                                |

Note the pattern: the mandatory set places the note in the vault and never paraphrases the title;
optional user tags (`exam-prep`, `dama-dmbok`, `project-atlas`) are the user's own cross-cutting
labels and always come last.
