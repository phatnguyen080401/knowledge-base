# Tag Taxonomy — Controlled Vocabulary

This is the complete list of tags an agent may assign to a note in `wiki/concepts/`. A tag that
does not appear in one of the three facet tables below may not be used unless the user explicitly
asked for it by name (see `SKILL.md`, Core Rule 3).

Every note carries **exactly one `domain` tag**, **at least one `topic` tag**, and **zero or one
`lifecycle` tag**, written in that order. A note never exceeds **10 tags in total**, counting any
optional user tags.

---

## Facet: `domain` — exactly one per note

The field the note belongs to. These are mutually exclusive; if two feel equally right, the note
probably covers two concepts and should be split (`AGENTS.md` §4.3).

| Tag                 | Covers                                                                                                | Excludes                                                                  |
| ------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `data-architecture` | Structural design of a data platform: layering, interfaces, semantic and ontology tiers, system topology | Engine-internal behaviour (`databases`); pipeline tooling (`data-engineering`) |
| `data-engineering`  | Building and operating pipelines and transformation tooling — ingestion, ELT, orchestration, adapters | The design of the platform those pipelines run on (`data-architecture`)   |
| `data-governance`   | Policy, accountability, and control over data as an organizational asset — quality, stewardship, master data, metadata, security | The technical mechanisms that implement a policy                          |
| `data-structures`   | Computer-science structures and the algorithms over them, independent of any product                  | Product-specific storage behaviour (`databases`)                          |
| `databases`         | Database and storage-engine behaviour: transactions, consistency models, replication, query execution | Vendor-neutral structure theory (`data-structures`)                       |

---

## Facet: `topic` — at least one per note

At least one is required: it narrows the note within its domain. Pick the most specific tag that
honestly fits, then add further topics only while each one carries information the others do not —
never pad the set by restating the domain or the note's own title. If no topic below fits a note you
are writing, that is a signal the vocabulary has a gap; propose a new tag rather than forcing a poor
match.

| Tag                   | Covers                                                                                           | Excludes                                                                |
| --------------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------- |
| `api-protocols`       | Interface and messaging styles for system-to-system exchange: REST, gRPC, SOAP, webhooks, queues | Internal representation of the data being exchanged (`data-modeling`)   |
| `data-modeling`       | Designing logical and semantic representations: entities, relationships, metrics, dimensional and warehouse models | Physical storage layout (`indexing`)                                    |
| `data-quality`        | Fitness for use — dimensions, profiling, validation rules, quality measurement and remediation   | Who is accountable for quality (that is the `data-governance` domain)   |
| `data-security`       | Protecting data from unauthorized access, loss, or misuse: access control, encryption, masking   | General platform reliability or availability                            |
| `data-warehouse`      | Cloud warehouse and lakehouse platforms: their storage/compute split, SQL dialects, and platform-specific behaviour | Vendor-neutral engine theory (`transactions`, `distributed-systems`)    |
| `distributed-systems` | Behaviour that only arises when data spans multiple nodes: partitioning, replication, consensus, network partitions | Single-node transactional semantics (`transactions`)                    |
| `indexing`            | Structures and techniques for locating records quickly: search trees, prefix trees, probabilistic filters, write-optimized stores | Abstract algorithm analysis unrelated to lookup                         |
| `master-data`         | Golden-record disciplines: entity resolution, survivorship, reference data, hierarchies           | Descriptive metadata about datasets (`metadata`)                        |
| `metadata`            | Data about data: catalogs, lineage, schema registries, business glossaries                        | The business data itself (`master-data`)                                |
| `transactions`        | Transactional guarantees and concurrency control: ACID, BASE, isolation levels, locking, MVCC    | Multi-node coordination concerns (`distributed-systems`)                |

---

## Facet: `lifecycle` — zero or one per note

| Tag            | Meaning                                                                             | Removed when                                          |
| -------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `needs-review` | Content is unverified, extrapolated, or conflicts with another page                  | The claim is confirmed or the conflict is resolved    |
| `stub`         | Placeholder — a definition and links, but no substantive body                        | The note gains real sections beyond the definition    |

---

## Banned Tags

Never assign these. Each is general, arbitrary, or uninformative — it would apply to nearly every
note in the vault and so tells a reader nothing. If the user requests one, say so and propose a
specific alternative before writing (`SKILL.md`, Core Rule 4).

| Banned tag                                              | Why                                                       | Use instead                          |
| ------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------ |
| `concept`, `note`, `wiki`, `knowledge`, `reference`     | Every file in `wiki/concepts/` is one                     | A `domain` tag                       |
| `data`, `tech`, `technology`, `general`, `misc`, `other`| Describes the whole vault, not the note                   | A `domain` tag                       |
| `important`, `interesting`, `useful`                    | Subjective; states nothing about the subject              | Nothing                              |
| `todo`, `wip`, `draft`                                  | Task state masquerading as a subject tag                  | `stub` or `needs-review`             |
| `system-design`                                         | Applies to almost every architecture note                 | `data-architecture` or `distributed-systems` |
| `database-concepts`, `programming`, `computer-science`  | Too broad to narrow a search                              | `databases` or `data-structures`     |

---

## Alias Map

Tags found in the vault that are not approved. Rewrite each to its canonical form during a tag
audit. `(retired)` means the tag carries no information the note's other tags do not already give —
drop it and confirm the mandatory set is still complete.

| Found tag             | Rewrite to                                                                     | Reason                                                              |
| --------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| `algorithm`           | `indexing`, or `(retired)`                                                      | Singular form; usually implied by the `data-structures` domain      |
| `algorithms`          | `indexing`, or `(retired)`                                                      | Implied by the `data-structures` domain; use `indexing` when the note is about lookup structures |
| `data_quality`        | `data-quality`                                                                  | `snake_case` → `kebab-case`                                         |
| `data-management`     | `data-governance`                                                               | Merged; the vault files management disciplines under governance     |
| `data-qualities`      | `data-quality`                                                                  | Plural form                                                         |
| `database`, `db`      | `databases`                                                                     | Canonical domain name                                               |
| `integration`         | `api-protocols` when the note is about system-to-system interfaces; `(retired)` on tooling notes | Ambiguous — conflates protocols, connectors, and ELT                |
| `stewardship`         | `(retired)`                                                                     | Implied by the `data-governance` domain                             |
| `system-design`       | `data-architecture` or `distributed-systems`                                    | Banned — too general                                                |

---

## Adding a Tag

Follow the "Adding a New Tag" section of `SKILL.md`. A candidate needs user approval, must apply to
three or more notes, must not be covered by an existing tag or combination, and must fit exactly one
facet. On approval, insert it into the correct table above in alphabetical order with a one-line
**Covers** and **Excludes** definition, then log the vocabulary change in `wiki/log.md`.
