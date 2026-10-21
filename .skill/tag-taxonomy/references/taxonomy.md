# Tag Taxonomy — Controlled Vocabulary

This is the complete list of tags an agent may assign to a note in `wiki/concepts/`. A `domain`,
`topic`, `concept`, `type`, or `lifecycle` tag that does not appear in its facet table below may not
be used unless the user explicitly asked for it by name (see `SKILL.md`, Core Rule 9). The `tech`
facet is open: its table is a seed list, not a gate.

Every note carries **exactly one `domain` tag** and **one to three `topic` tags**, and every
substantive note adds at least one `concept` or `tech` tag. Tags are written in facet order:

```yaml
tags: [<domain>, <topic…>, <concept…>, <tech…>, <type>, <lifecycle>, <user…>]
```

A note never exceeds **10 tags in total**, counting any optional user tags.

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
| `devops`            | Building, shipping, and operating software: CI/CD pipelines, artifacts and registries, infrastructure provisioning, and supply-chain and runtime security | The design of the software being shipped (`software-architecture`); pipelines that move *data* rather than code (`data-engineering`) |
| `software-architecture` | Design and engineering practice for software systems generally, independent of the data they carry: release and dependency management, versioning schemes, API contracts, module boundaries, deployment patterns | Structural design of a *data* platform (`data-architecture`); pipeline and transformation tooling (`data-engineering`); the tooling that actually builds, ships, and secures an artifact (`devops`) |

---

## Facet: `topic` — one to three per note

At least one is required: it narrows the note within its domain. Pick the most specific tag that
honestly fits, then add further topics only while each one carries information the others do not —
never pad the set by restating the domain or the note's own title. If no topic below fits a note you
are writing, that is a signal the vocabulary has a gap; propose a new tag rather than forcing a poor
match.

| Tag                   | Covers                                                                                           | Excludes                                                                |
| --------------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------- |
| `api-protocols`       | Interface and messaging styles for system-to-system exchange: REST, gRPC, SOAP, webhooks, queues | Internal representation of the data being exchanged (`data-modeling`)   |
| `architecture-patterns` | Recurring structural shapes of a system: layering, module boundaries, coupling, deployment topology | The named technology realizing the pattern (a `tech` tag)           |
| `concurrency`         | Executing work simultaneously inside one system: threads, processes, event loops, synchronization primitives, races, and runtime constraints on parallelism | Coordination across nodes (`distributed-systems`); database transaction semantics (`transactions`) |
| `cost-management`     | Spend visibility and control: pricing models, cost attribution, budgets, slot and credit usage   | Making a query faster for its own sake (`query-optimization`)           |
| `data-modeling`       | Designing logical and semantic representations: entities, relationships, metrics, dimensional and warehouse models | Physical storage layout (`indexing`)                                    |
| `data-quality`        | Fitness for use — dimensions, profiling, validation rules, quality measurement and remediation   | Who is accountable for quality (that is the `data-governance` domain)   |
| `data-security`       | Protecting data from unauthorized access, loss, or misuse: access control, encryption, masking   | General platform reliability or availability                            |
| `data-warehouse`      | Cloud warehouse and lakehouse platforms: their storage/compute split, SQL dialects, and platform-specific behaviour | Vendor-neutral engine theory (`transactions`, `distributed-systems`)    |
| `deployment`          | Getting code and pipelines into an environment: packaging, release automation, runtime hosting, rollback | Which version number the artifact carries (`versioning`)                |
| `distributed-systems` | Behaviour that only arises when data spans multiple nodes: partitioning, replication, consensus, network partitions | Single-node transactional semantics (`transactions`)                    |
| `elt`                 | Extract-load-transform practice and tooling: models, materializations, tests, scheduling, adapters | The warehouse the transforms run on (`data-warehouse`)                  |
| `indexing`            | Structures and techniques for locating records quickly: search trees, prefix trees, probabilistic filters, write-optimized stores | Abstract algorithm analysis unrelated to lookup                         |
| `master-data`         | Golden-record disciplines: entity resolution, survivorship, reference data, hierarchies           | Descriptive metadata about datasets (`metadata`)                        |
| `metadata`            | Data about data: catalogs, lineage, schema registries, business glossaries                        | The business data itself (`master-data`)                                |
| `transactions`        | Transactional guarantees and concurrency control: ACID, BASE, isolation levels, locking, MVCC    | Multi-node coordination concerns (`distributed-systems`)                |
| `versioning`          | How artifacts are numbered, released, and depended upon: version schemes, compatibility contracts, pinning and lockfiles, deprecation windows | The design of the interface being versioned (`api-protocols`)           |

---

## Facet: `concept` — zero to four per note

The mechanisms and ideas the note actually **explains**, not the ones it mentions in passing. This
is the facet that makes the vault searchable across domains: `replication` finds the database note
and the architecture note alike. A concept tag must be shared by at least two notes — one that fits
a single page is that page's title, not a classification.

| Tag                        | Covers                                                                                        | Excludes                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `access-control`           | Deciding who may read or write what: roles, grants, row and column policies, least privilege  | Encrypting the data itself                                      |
| `ci-cd`                    | Automated build, test, and release pipelines triggered by source changes                      | The runtime the artifact lands on (`deployment`)                |
| `compatibility-contracts`  | Promises an interface makes across versions: backward and forward compatibility, deprecation  | The numbering scheme carrying the promise (`versioning`)        |
| `concurrency-control`      | Coordinating simultaneous readers and writers: locking, MVCC, serialization, anomalies        | Durability and crash recovery                                   |
| `consistency-models`       | What a reader is guaranteed to see and when: strong, eventual, causal, linearizable           | The mechanism copying the data (`replication`)                  |
| `data-lineage`             | Tracing data from source to consumer: column- and table-level provenance, impact analysis     | The catalog product storing it (a `tech` tag)                   |
| `data-validation`          | Checking data against expectations: profiling, rules, assertions, tests, anomaly detection    | Who is accountable for acting on a failure (`stewardship-roles`)|
| `entity-resolution`        | Deciding that two records describe the same real-world thing: matching, merging, survivorship | Storing the resulting golden record                             |
| `fault-tolerance`          | Surviving node, network, or process failure: failover, retries, quorums, degraded modes       | Routine performance tuning                                      |
| `knowledge-graph`          | Representing meaning as typed entities and relationships: ontologies, triples, inference      | Tabular and dimensional models (`data-modeling`)                |
| `metric-definition`        | Declaring a business measure once and reusing it: metric specs, dimensions, governed KPIs     | The physical aggregate table behind it                          |
| `partitioning`             | Splitting data across nodes, files, or ranges: sharding, partition keys, pruning, skew        | Copying the same data to several nodes (`replication`)          |
| `prefix-structures`        | Keys indexed by position in the string: tries, radix and PATRICIA trees, autocomplete         | Comparison-based ordered structures (`search-trees`)            |
| `probabilistic-structures` | Structures trading exactness for space: Bloom filters, HyperLogLog, sketches                  | Exact ordered lookup structures (`search-trees`)                |
| `query-optimization`       | Making a query do less work: planning, pruning, join strategy, clustering, materialization    | Reducing spend as a goal in itself (`cost-management`)          |
| `replication`              | Maintaining copies of the same data across nodes: leader/follower, sync vs async, lag         | Splitting distinct data across nodes (`partitioning`)           |
| `schema-evolution`         | Changing a schema without breaking readers: migrations, additive change, contract tests       | Designing the schema in the first place (`data-modeling`)       |
| `search-trees`             | Ordered, balanced lookup structures: B-trees, B+ trees, fanout, range scans                   | Write-optimized log structures (`write-optimization`)           |
| `stewardship-roles`        | Human accountability for data: owners, stewards, councils, decision rights, escalation        | The policies they enforce (the `data-governance` domain)        |
| `write-optimization`       | Favouring write throughput over read simplicity: LSM trees, memtables, compaction, buffering  | Read-optimized ordered structures (`search-trees`)              |

---

## Facet: `tech` — zero to four per note, open vocabulary

Named products, platforms, services, and standards the note is substantively about. **This is the
only facet you may extend without asking.** Its rules are formal, not editorial:

- Canonical lowercase `kebab-case` name as the vendor writes it: `bigquery`, `cloud-run`,
  `github-actions`. No vendor prefix (`google-bigquery`), no capitals, no `#`.
- Never a version number — `dbt`, not `dbt-1-8`. Version-specific facts belong in the note body.
- Never a category pretending to be a product: `warehouse`, `orchestrator`, and `cloud` are topics
  or nothing at all.
- A product mentioned once as an example does not earn a tag; the note must be *about* it.
- Unlike every other facet, a `tech` tag **may** repeat the note's own title — `dbt.md` carries
  `dbt` so it clusters with its adapter and deployment notes.

Seed list — add a row once a second note uses the tag:

| Tag              | Covers                                                         |
| ---------------- | -------------------------------------------------------------- |
| `bigquery`       | Google BigQuery: its SQL dialect, slots, storage, and pricing  |
| `cloud-run`      | Google Cloud Run services and jobs                             |
| `databricks`     | Databricks lakehouse, Unity Catalog, Delta tables              |
| `dbt`            | dbt Core and dbt Cloud: models, tests, macros, adapters        |
| `fix-protocol`   | The FIX financial messaging standard                           |
| `github-actions` | GitHub Actions workflows, runners, and secrets                 |
| `python`         | The Python language and CPython runtime: stdlib modules, interpreter behaviour |

---

## Facet: `type` — zero or one per note

The *shape* of the note, so an agent knows how to read it before opening it. Most notes are ordinary
explanations and take no type tag.

| Tag          | Meaning                                                                      | Not this                                                     |
| ------------ | ------------------------------------------------------------------------------ | ------------------------------------------------------------- |
| `comparison` | The note's subject *is* the difference between two or more things            | A note explaining one thing that mentions another            |
| `how-to`     | An ordered procedure the reader is meant to execute                          | A note describing how something works internally             |
| `overview`   | A hub that defines a field and routes to its child notes                     | A `stub` — an overview is short by design, not unfinished    |

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
specific alternative before writing (`SKILL.md`, Core Rule 5).

| Banned tag                                              | Why                                                       | Use instead                          |
| ------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------ |
| `concept`, `note`, `wiki`, `knowledge`, `reference`     | Every file in `wiki/concepts/` is one (the `concept` *facet* is a category of tags, never a tag itself) | A `domain` tag                       |
| `data`, `tech`, `technology`, `general`, `misc`, `other`| Describes the whole vault, not the note                   | A `domain` tag                       |
| `important`, `interesting`, `useful`                    | Subjective; states nothing about the subject              | Nothing                              |
| `todo`, `wip`, `draft`                                  | Task state masquerading as a subject tag                  | `stub` or `needs-review`             |
| `architecture`, `design`, `system-design` | Applies to almost every architecture note              | `architecture-patterns`, `concurrency`, `data-architecture`, or `distributed-systems` |
| `database-concepts`, `programming`, `computer-science`  | Too broad to narrow a search                              | `databases` or `data-structures`     |
| `cloud`, `platform`, `tool`, `framework`, `warehouse`   | A category, not a product — a `tech` tag must name one    | The product's own name, or a `topic` tag |
| `dbt-1-8`, `python-3-12`, any version-numbered tag      | Pins the tag to a release the note will outlive           | The unversioned `tech` tag; put the version in the body |

---

## Retired Tags

Tags this vault **once used and deliberately dropped**. Each row records a judgement that cannot be
re-derived from the tables above, so an agent meeting the old tag on a hand-edited or imported note
rewrites it without re-litigating the decision. Every entry here is real vault history, traceable to
a `wiki/log.md` audit — this table is not a place to pre-empt spellings nobody has used.

| Retired tag               | Rewrite to                                                  | Retired because                                                                  |
| ------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| `algorithm`, `algorithms` | `indexing`, or drop                                          | Implied by the `data-structures` domain; `indexing` only when the note is about lookup |
| `data-management`         | `data-governance`                                            | Merged — the vault files management disciplines under governance                 |
| `integration`             | `api-protocols` on interface notes, `elt` on tooling notes   | Ambiguous — conflated protocols, connectors, and ELT                             |
| `mdm`                     | `master-data`                                                | Unexpanded acronym; the facet tables spell concepts out                          |
| `roles`, `stewardship`    | `stewardship-roles`                                          | Too broad alone; promoted to the `concept` facet with a sharper definition       |
| `security`                | `data-security`                                              | Bare `security` reads as infrastructure security, not data security              |

**Anything else is a typo, not an alias.** A `domain`, `topic`, `concept`, or `type` tag must appear
verbatim in a table above, so a case, plural, separator, acronym, or vendor-prefix variant
(`Data Quality`, `data_quality`, `data-qualities`, `db`, `google-bigquery`, `dbt-core`) can only
arrive by hand. Rewrite it to the entry it obviously means — it needs no row here, and adding one
would only duplicate the facet tables and give the vocabulary a second place to drift.

---

## Adding a Tag

Follow the "Adding a New Tag" section of `SKILL.md`. A `tech` tag needs no approval — just the
formal rules above, plus a seed-list row once a second note uses it. Every other facet is closed: a
candidate needs user approval, must not be covered by an existing tag or combination, must fit
exactly one facet, and must apply to three or more notes (two for a `concept`). On approval, insert
it into the correct table above in alphabetical order with a one-line **Covers** and **Excludes**
definition, then log the vocabulary change in `wiki/log.md`.
