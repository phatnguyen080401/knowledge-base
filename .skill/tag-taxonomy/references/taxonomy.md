# Tag Taxonomy — Controlled Vocabulary

The approved tags; the rules are in [SKILL.md](../SKILL.md). Closed facets (`domain`, `topic`,
`concept`, `type`, `lifecycle`) are gates: a tag missing from its table is either a proposal that
needs approval or, when the user asks for it by name, a *user tag* listed last. The `tech` facet is
open; its table is a seed list.

## Facet: `domain` — exactly one per note

**This table is the authoritative list of domain folders** (`AGENTS.md` §2). Adding a row means
creating a folder, which needs user approval.

| Tag | Folder | Covers | Excludes |
| --- | --- | --- | --- |
| `ai-engineering` | `ai_engineering/` | Building and operating applications on top of machine-learning and foundation models: prompting, retrieval, agents, evaluation, inference serving, and the ops around them | Pipelines that move and transform data (`data-engineering`); general software design (`software-architecture`) |
| `data-architecture` | `data_architecture/` | Structural design of a data platform: layering, interfaces, semantic and ontology tiers, system topology | Engine-internal behaviour (`databases`); pipeline tooling (`data-engineering`) |
| `data-engineering` | `data_engineering/` | Building and operating pipelines and transformation tooling — ingestion, ELT, orchestration, adapters | The design of the platform those pipelines run on (`data-architecture`) |
| `data-governance` | `data_governance/` | Policy, accountability, and control over data as an organizational asset — quality, stewardship, master data, metadata, security | The technical mechanisms that implement a policy |
| `data-structures` | `data_structures/` | Computer-science structures and the algorithms over them, independent of any product | Product-specific storage behaviour (`databases`) |
| `databases` | `databases/` | Database and storage-engine behaviour: transactions, consistency models, replication, query execution | Vendor-neutral structure theory (`data-structures`) |
| `devops` | `devops/` | Building, shipping, and operating software: CI/CD pipelines, artifacts and registries, infrastructure provisioning, and supply-chain and runtime security | The design of the software being shipped (`software-architecture`); pipelines that move *data* rather than code (`data-engineering`) |
| `identity-and-access` | `identity_and_access/` | Proving who a user or service is and deciding what it may do: authentication and authorization protocols, tokens and federation, single sign-on, access-control models | The data-protection policy those controls enforce (`data-governance`); build and pipeline security (`devops`) |
| `software-architecture` | `software_architecture/` | Design and engineering practice for software systems generally, independent of the data they carry: release and dependency management, versioning schemes, API contracts, module boundaries, deployment patterns | Structural design of a *data* platform (`data-architecture`); pipeline and transformation tooling (`data-engineering`); the tooling that actually builds, ships, and secures an artifact (`devops`); authentication and authorization mechanisms (`identity-and-access`) |
| `version-control` | `version_control/` | Managing source history in a repository: commit conventions and messages, branching and merge strategies, tags, rebasing, history rewriting, and the review workflows built on them | The pipelines a commit triggers (`devops`); how the resulting artifact is numbered and depended upon (`software-architecture`) |

## Facet: `topic` — one to three per note

| Tag | Covers | Excludes |
| --- | --- | --- |
| `access-management` | Proving identity and granting permissions: authentication factors, authorization models, sessions and tokens, federation, single sign-on | Protecting the data itself (`data-security`); build and pipeline protection (`supply-chain-security`) |
| `api-protocols` | Interface and messaging styles for system-to-system exchange: REST, gRPC, SOAP, webhooks, queues | Internal representation of the data being exchanged (`data-modeling`) |
| `architecture-patterns` | Recurring structural shapes of a system: layering, module boundaries, coupling, deployment topology | The named technology realizing the pattern (a `tech` tag) |
| `concurrency` | Executing work simultaneously inside one system: threads, processes, event loops, synchronization primitives, races, and runtime constraints on parallelism | Coordination across nodes (`distributed-systems`); database transaction semantics (`transactions`) |
| `cost-management` | Spend visibility and control: pricing models, cost attribution, budgets, slot and credit usage | Making a query faster for its own sake (`query-optimization`) |
| `data-modeling` | Designing logical and semantic representations: entities, relationships, metrics, dimensional and warehouse models | Physical storage layout (`indexing`) |
| `data-quality` | Fitness for use — dimensions, profiling, validation rules, quality measurement and remediation | Who is accountable for quality (that is the `data-governance` domain) |
| `data-security` | Protecting data from unauthorized access, loss, or misuse: access control, encryption, masking | General platform reliability or availability |
| `data-warehouse` | Cloud warehouse and lakehouse platforms: their storage/compute split, SQL dialects, and platform-specific behaviour | Vendor-neutral engine theory (`transactions`, `distributed-systems`) |
| `deployment` | Getting code and pipelines into an environment: packaging, release automation, runtime hosting, rollback | Which version number the artifact carries (`versioning`) |
| `distributed-systems` | Behaviour that only arises when data spans multiple nodes: partitioning, replication, consensus, network partitions | Single-node transactional semantics (`transactions`) |
| `elt` | Extract-load-transform practice and tooling: models, materializations, tests, scheduling, adapters | The warehouse the transforms run on (`data-warehouse`) |
| `indexing` | Structures and techniques for locating records quickly: search trees, prefix trees, probabilistic filters, write-optimized stores | Abstract algorithm analysis unrelated to lookup |
| `llm-applications` | Building products on foundation models: prompting, retrieval-augmented generation, tool use and agents, context handling, output evaluation | Training or fine-tuning the model itself (`model-operations`) |
| `master-data` | Golden-record disciplines: entity resolution, survivorship, reference data, hierarchies | Descriptive metadata about datasets (`metadata`) |
| `metadata` | Data about data: catalogs, lineage, schema registries, business glossaries | The business data itself (`master-data`) |
| `model-operations` | Getting models into and keeping them in production: serving and inference, versioning and registries, monitoring, drift, cost and latency management | The application logic built on top of the model (`llm-applications`) |
| `observers` | Watching running software to explain its behaviour: logs, metrics, traces, their correlation, dashboards, and alerting | Monitoring a model's quality and drift (`model-operations`); build-time scanning (`supply-chain-security`) |
| `source-history` | Recording and reshaping a repository's commit history: staging and committing, branching, merging, rebasing, history rewriting, remotes and synchronization | How the resulting artifact is numbered and released (`versioning`); the pipelines a commit triggers (`ci-cd`) |
| `supply-chain-security` | Trusting what goes into a build and who can change it: vulnerability, secret, misconfiguration, and licence scanning; SBOMs; signing; branch and pipeline protection | Protecting the business data a system holds (`data-security`) |
| `transactions` | Transactional guarantees and concurrency control: ACID, BASE, isolation levels, locking, MVCC | Multi-node coordination concerns (`distributed-systems`) |
| `versioning` | How artifacts are numbered, released, and depended upon: version schemes, compatibility contracts, pinning and lockfiles, deprecation windows | The design of the interface being versioned (`api-protocols`) |

## Facet: `concept` — zero to four per note

The mechanisms a note explains; the facet that connects notes across domains.

| Tag | Covers | Excludes |
| --- | --- | --- |
| `access-control` | Deciding who may read or write what: roles, grants, row and column policies, least privilege | Encrypting the data itself |
| `ci-cd` | Automated build, test, and release pipelines triggered by source changes | The runtime the artifact lands on (`deployment`) |
| `compatibility-contracts` | Promises an interface makes across versions: backward and forward compatibility, deprecation | The numbering scheme carrying the promise (`versioning`) |
| `concurrency-control` | Coordinating simultaneous readers and writers: locking, MVCC, serialization, anomalies | Durability and crash recovery |
| `consistency-models` | What a reader is guaranteed to see and when: strong, eventual, causal, linearizable | The mechanism copying the data (`replication`) |
| `data-lineage` | Tracing data from source to consumer: column- and table-level provenance, impact analysis | The catalog product storing it (a `tech` tag) |
| `data-validation` | Checking data against expectations: profiling, rules, assertions, tests, anomaly detection | Who is accountable for acting on a failure (`stewardship-roles`) |
| `entity-resolution` | Deciding that two records describe the same real-world thing: matching, merging, survivorship | Storing the resulting golden record |
| `fault-tolerance` | Surviving node, network, or process failure: failover, retries, quorums, degraded modes | Routine performance tuning |
| `in-context-learning` | Steering a model at inference time through instructions and demonstrations in the prompt, with no weight updates: zero-, one-, and few-shot prompting, chain-of-thought, self-consistency | Grounding in retrieved knowledge (`retrieval-augmentation`); training or fine-tuning (`model-operations`) |
| `knowledge-graph` | Representing meaning as typed entities and relationships: ontologies, triples, inference | Tabular and dimensional models (`data-modeling`) |
| `metric-definition` | Declaring a business measure once and reusing it: metric specs, dimensions, governed KPIs | The physical aggregate table behind it |
| `partitioning` | Splitting data across nodes, files, or ranges: sharding, partition keys, pruning, skew | Copying the same data to several nodes (`replication`) |
| `prefix-structures` | Keys indexed by position in the string: tries, radix and PATRICIA trees, autocomplete | Comparison-based ordered structures (`search-trees`) |
| `probabilistic-structures` | Structures trading exactness for space: Bloom filters, HyperLogLog, sketches | Exact ordered lookup structures (`search-trees`) |
| `query-optimization` | Making a query do less work: planning, pruning, join strategy, clustering, materialization | Reducing spend as a goal in itself (`cost-management`) |
| `replication` | Maintaining copies of the same data across nodes: leader/follower, sync vs async, lag | Splitting distinct data across nodes (`partitioning`) |
| `retrieval-augmentation` | Grounding a model's generation in externally retrieved knowledge: chunking, embedding and hybrid search, reranking, context assembly, agent traversal | Encoding knowledge into model weights by training or fine-tuning (`model-operations`) |
| `schema-evolution` | Changing a schema without breaking readers: migrations, additive change, contract tests | Designing the schema in the first place (`data-modeling`) |
| `search-trees` | Ordered, balanced lookup structures: B-trees, B+ trees, fanout, range scans | Write-optimized log structures (`write-optimization`) |
| `stewardship-roles` | Human accountability for data: owners, stewards, councils, decision rights, escalation | The policies they enforce (the `data-governance` domain) |
| `write-optimization` | Favouring write throughput over read simplicity: LSM trees, memtables, compaction, buffering | Read-optimized ordered structures (`search-trees`) |

## Facet: `tech` — zero to four per note, open

Rules in SKILL.md (*`tech` is open*). Seed list — add a row once a second note uses the tag:

| Tag | Covers |
| --- | --- |
| `bigquery` | Google BigQuery: its SQL dialect, slots, storage, and pricing |
| `cloud-run` | Google Cloud Run services and jobs |
| `databricks` | Databricks lakehouse, Unity Catalog, Delta tables |
| `dbt` | dbt Core and dbt Cloud: models, tests, macros, adapters |
| `fix-protocol` | The FIX financial messaging standard |
| `git` | The Git version-control system: commits, branches, tags, trailers, rebase |
| `github-actions` | GitHub Actions workflows, runners, and secrets |
| `jwt` | JSON Web Tokens: JWS/JWE structure, claims, validation, algorithm attacks |
| `kafka` | Apache Kafka: topics, partitions, consumer groups, transactions, Kafka Streams |
| `oauth` | The OAuth 2.0 and 2.1 authorization frameworks: grants, tokens, scopes, PKCE |
| `openid-connect` | OpenID Connect: ID tokens, discovery, UserInfo, federation on OAuth 2.0 |
| `python` | The Python language and CPython runtime: stdlib modules, interpreter behaviour |
| `spark` | Apache Spark: execution model, Spark SQL, Structured Streaming |

## Facet: `type` — zero or one per note

| Tag | Meaning | Not this |
| --- | --- | --- |
| `comparison` | The note's subject *is* the difference between two or more things | A note explaining one thing that mentions another |
| `how-to` | An ordered procedure the reader is meant to execute | A note describing how something works internally |
| `overview` | A hub that defines a field and routes to its child notes | A `stub` — an overview is short by design, not unfinished |

## Facet: `lifecycle` — zero or one per note

| Tag | Meaning | Removed when |
| --- | --- | --- |
| `needs-review` | Content is unverified, extrapolated, or conflicts with another page | The claim is confirmed or the conflict is resolved |
| `stub` | Placeholder — a definition and links, but no substantive body | The note gains real sections beyond the definition |

## Banned Tags

Never assign these (SKILL.md, *Every tag must exclude something*).

| Banned | Use instead |
| --- | --- |
| `concept`, `note`, `wiki`, `knowledge`, `reference` (the `concept` *facet* is never a tag) | A `domain` tag |
| `data`, `tech`, `technology`, `general`, `misc`, `other` | A `domain` tag |
| `important`, `interesting`, `useful` | Nothing |
| `todo`, `wip`, `draft` | `stub` or `needs-review` |
| `architecture`, `design`, `system-design` | `architecture-patterns`, `concurrency`, `data-architecture`, or `distributed-systems` |
| `database-concepts`, `programming`, `computer-science` | `databases` or `data-structures` |
| `cloud`, `platform`, `tool`, `framework`, `warehouse` | The product's own name, or a `topic` tag |
| `dbt-1-8`, `python-3-12`, any version-numbered tag | The unversioned `tech` tag; the version goes in the body |
