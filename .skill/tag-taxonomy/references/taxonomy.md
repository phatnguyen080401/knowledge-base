# Tag Taxonomy — Controlled Vocabulary

The approved tags; the rules are in [SKILL.md](../SKILL.md). Closed facets (`domain`, `topic`,
`concept`, `type`, `lifecycle`) are gates: a tag missing from its table is either a proposal that
needs approval or, when the user asks for it by name, a *user tag* listed last. The `tech` facet is
open; its table is a seed list.

## Index

Every tag name, for choosing candidates; grep a candidate's row below for its Covers and Excludes.

- **domain:** ai-engineering, cloud-computing, data-architecture, data-engineering, data-governance, data-structures, databases, devops, identity-and-access, linux, machine-learning, software-architecture, version-control
- **topic:** access-management, ai-safety, api-protocols, architecture-patterns, concurrency, cost-management, data-modeling, data-quality, data-security, data-warehouse, deployment, distributed-systems, elt, generative-models, indexing, llm-applications, master-data, metadata, model-operations, model-training, observers, os-internals, representation-learning, source-history, supply-chain-security, system-administration, transactions, versioning
- **concept:** access-control, ci-cd, compatibility-contracts, concurrency-control, consistency-models, data-lineage, data-validation, decoding-strategies, entity-resolution, fault-tolerance, in-context-learning, knowledge-graph, learning-paradigms, linear-regression, metric-definition, parallel-decoding, partitioning, prefix-structures, probabilistic-structures, process-isolation, query-optimization, replication, retrieval-augmentation, scaling-laws, schema-evolution, search-trees, sequence-modeling, specification-gaming, stewardship-roles, stochastic-optimization, vector-quantization, write-optimization
- **tech:** aws, bigquery, cloud-run, databricks, dbt, docker, fix-protocol, flink, git, github-actions, jwt, kafka, kubernetes, oauth, openid-connect, python, spark, terraform (seed list; open)
- **type:** comparison, how-to, overview
- **lifecycle:** needs-review, stub

## Facet: `domain` — exactly one per note

**This table is the authoritative list of domain folders** (`AGENTS.md` §2). Adding a row means
creating a folder, which needs user approval.

| Tag | Folder | Covers | Excludes |
| --- | --- | --- | --- |
| `ai-engineering` | `ai_engineering/` | Building and operating applications on top of machine-learning and foundation models: prompting, retrieval, agents, evaluation, inference serving, and the ops around them | Pipelines that move and transform data (`data-engineering`); general software design (`software-architecture`); the learning algorithms themselves (`machine-learning`) |
| `cloud-computing` | `cloud_computing/` | Public-cloud platforms and their managed services: compute, database, storage, and analytics offerings, with their pricing models and operating limits | Provider-agnostic provisioning and delivery tooling (`devops`); pipeline design independent of the service that runs it (`data-engineering`); engine-internal database behaviour (`databases`) |
| `data-architecture` | `data_architecture/` | Structural design of a data platform: layering, interfaces, semantic and ontology tiers, system topology | Engine-internal behaviour (`databases`); pipeline tooling (`data-engineering`) |
| `data-engineering` | `data_engineering/` | Building and operating pipelines and transformation tooling — ingestion, ELT, orchestration, adapters | The design of the platform those pipelines run on (`data-architecture`) |
| `data-governance` | `data_governance/` | Policy, accountability, and control over data as an organizational asset — quality, stewardship, master data, metadata, security | The technical mechanisms that implement a policy |
| `data-structures` | `data_structures/` | Computer-science structures and the algorithms over them, independent of any product | Product-specific storage behaviour (`databases`) |
| `databases` | `databases/` | Database and storage-engine behaviour: transactions, consistency models, replication, query execution | Vendor-neutral structure theory (`data-structures`) |
| `devops` | `devops/` | Building, shipping, and operating software: CI/CD pipelines, artifacts and registries, infrastructure provisioning, and supply-chain and runtime security | The design of the software being shipped (`software-architecture`); pipelines that move *data* rather than code (`data-engineering`) |
| `identity-and-access` | `identity_and_access/` | Proving who a user or service is and deciding what it may do: authentication and authorization protocols, tokens and federation, single sign-on, access-control models | The data-protection policy those controls enforce (`data-governance`); build and pipeline security (`devops`) |
| `linux` | `linux/` | The Linux operating system as administered and as a platform: boot and init, systemd units and targets, services, processes and signals, users and permissions, filesystems, and kernel features such as namespaces and cgroups | Container and orchestration tooling built on those kernel features (`devops`); managed cloud services (`cloud-computing`) |
| `machine-learning` | `machine_learning/` | Learning algorithms and the models they produce, independent of any product built on them: training objectives, model architectures, optimization, representation learning, and evaluating the model itself | Building and operating applications on trained models (`ai-engineering`); pipelines that prepare the training data (`data-engineering`) |
| `software-architecture` | `software_architecture/` | Design and engineering practice for software systems generally, independent of the data they carry: release and dependency management, versioning schemes, API contracts, module boundaries, deployment patterns | Structural design of a *data* platform (`data-architecture`); pipeline and transformation tooling (`data-engineering`); the tooling that actually builds, ships, and secures an artifact (`devops`); authentication and authorization mechanisms (`identity-and-access`) |
| `version-control` | `version_control/` | Managing source history in a repository: commit conventions and messages, branching and merge strategies, tags, rebasing, history rewriting, and the review workflows built on them | The pipelines a commit triggers (`devops`); how the resulting artifact is numbered and depended upon (`software-architecture`) |

## Facet: `topic` — one to three per note

The area of practice a note sits in, broad enough to hold several concepts.

| Tag | Covers | Excludes |
| --- | --- | --- |
| `access-management` | Proving identity and carrying permissions between systems: authentication factors, sessions and tokens, authorization protocols, federation, single sign-on | The permission model itself (tag `access-control` too); protecting the data itself (`data-security`); build and pipeline protection (`supply-chain-security`) |
| `ai-safety` | Capability levels beyond today's systems (AGI, superintelligence) and keeping them beneficial: alignment, control, dangerous-capability evaluations, AI risk and governance | Building products on models (`llm-applications`); serving and monitoring models in production (`model-operations`) |
| `api-protocols` | Interface and messaging styles for system-to-system exchange: REST, gRPC, SOAP, webhooks, queues | Internal representation of the data being exchanged (`data-modeling`) |
| `architecture-patterns` | Recurring structural shapes of a system: layering, module boundaries, coupling, deployment topology | The named technology realizing the pattern (a `tech` tag) |
| `concurrency` | Executing work simultaneously inside one system: threads, processes, event loops, synchronization primitives, races, and runtime constraints on parallelism | Coordination across nodes (`distributed-systems`); database transaction semantics (`transactions`) |
| `cost-management` | Spend visibility and control: pricing models, cost attribution, budgets, slot and credit usage | Making a query faster for its own sake (`query-optimization`) |
| `data-modeling` | Designing logical and semantic representations: entities, relationships, metrics, dimensional and warehouse models | Physical storage layout (`indexing`) |
| `data-quality` | Fitness for use: quality dimensions, measurement, and remediation | Who is accountable for quality (the `data-governance` domain); the checks that test data (tag `data-validation` too) |
| `data-security` | Protecting data from unauthorized access, loss, or misuse: encryption, masking | General platform reliability or availability; who may read or write what (tag `access-control` too) |
| `data-warehouse` | Cloud warehouse and lakehouse platforms: their storage/compute split, SQL dialects, and platform-specific behaviour | Vendor-neutral engine theory (`transactions`, `distributed-systems`) |
| `deployment` | Getting a built artifact running in an environment: packaging, environment provisioning, runtime hosting, rollout and rollback | The pipeline that builds and releases it (tag `ci-cd` too); which version number it carries (`versioning`) |
| `distributed-systems` | Behaviour that only arises when data spans multiple nodes: consensus, coordination, network partitions | Single-node transactional semantics (`transactions`); splitting or copying the data (tag `partitioning` or `replication` too) |
| `elt` | Extract-load-transform practice and tooling: models, materializations, tests, scheduling, adapters | The warehouse the transforms run on (`data-warehouse`) |
| `generative-models` | Architectures and training objectives of models that generate text, images, or audio: autoregressive, diffusion, flow, latent, and quantized generative models | Serving those models in production (`model-operations`); building applications on them (`llm-applications`) |
| `indexing` | Locating records quickly: choosing an index structure, its lookup and update costs | Abstract algorithm analysis unrelated to lookup; each structure family (tag `search-trees`, `prefix-structures`, `probabilistic-structures`, or `write-optimization` too) |
| `llm-applications` | Building products on foundation models: tool use and agents, context handling, output evaluation | Training or fine-tuning the model itself (`model-operations`); prompting and retrieval techniques (tag `in-context-learning` or `retrieval-augmentation` too) |
| `master-data` | Golden-record disciplines: one trusted record per entity, reference data, hierarchies | Descriptive metadata about datasets (`metadata`); matching and survivorship (tag `entity-resolution` too) |
| `metadata` | Data about data: catalogs, schema registries, business glossaries | The business data itself (`master-data`); source-to-consumer tracing (tag `data-lineage` too) |
| `model-operations` | Getting models into and keeping them in production: serving and inference, versioning and registries, monitoring, drift, cost and latency management | The application logic built on top of the model (`llm-applications`) |
| `model-training` | Fitting a model's parameters to data: loss functions, gradient descent, regularization, backpropagation | What the learned parameters represent (`representation-learning`); serving the trained model (`model-operations`); minibatch, momentum, and adaptive optimizers (tag `stochastic-optimization` too) |
| `observers` | Watching running software to explain its behaviour: logs, metrics, traces, their correlation, dashboards, and alerting | Monitoring a model's quality and drift (`model-operations`); build-time scanning (`supply-chain-security`) |
| `os-internals` | How the operating system runs programs: process lifecycle and signals, file descriptors, standard streams, linking and loading, kernel features | Running work in parallel (`concurrency`); configuring and maintaining a host (`system-administration`); isolating processes with namespaces and cgroups (tag `process-isolation` too) |
| `representation-learning` | Learning dense or discrete vector representations of words, text, images, or other inputs: word vectors, sentence encoders, embedding training objectives, codebook tokenizers | Generating outputs from those representations (`generative-models`); applications that search with them (`llm-applications`) |
| `source-history` | Recording and reshaping a repository's commit history: staging and committing, branching, merging, rebasing, history rewriting, remotes and synchronization | How the resulting artifact is numbered and released (`versioning`); the pipelines a commit triggers (`ci-cd`) |
| `supply-chain-security` | Trusting what goes into a build and who can change it: vulnerability, secret, misconfiguration, and licence scanning; SBOMs; signing; branch and pipeline protection | Protecting the business data a system holds (`data-security`) |
| `system-administration` | Configuring and maintaining a host: boot and init, services, package and runtime installation, users and permissions | How the kernel runs programs underneath (`os-internals`); provisioning environments as code (`deployment`) |
| `transactions` | Transactional guarantees: ACID, BASE, isolation levels, commit, durability, and recovery | Multi-node coordination (`distributed-systems`); the locking and MVCC that enforce isolation (tag `concurrency-control` too) |
| `versioning` | How artifacts are numbered, released, and depended upon: version schemes, pinning and lockfiles | The design of the interface being versioned (`api-protocols`); the compatibility and deprecation promises a version makes (tag `compatibility-contracts` too) |

## Facet: `concept` — zero to four per note

Named mechanisms, techniques, structures, and models a note explains, recurring across fields or
within one. A note takes its concepts alongside the topic it sits in.

| Tag | Covers | Excludes |
| --- | --- | --- |
| `access-control` | Deciding who may read or write what: roles, grants, row and column policies, least privilege | Encrypting the data itself |
| `ci-cd` | Automated build, test, and release pipelines triggered by source changes | The runtime the artifact lands on (`deployment`) |
| `compatibility-contracts` | Promises an interface makes across versions: backward and forward compatibility, deprecation | The numbering scheme carrying the promise (`versioning`) |
| `concurrency-control` | Coordinating simultaneous readers and writers: locking, MVCC, serialization, anomalies | Durability and crash recovery |
| `consistency-models` | What a reader is guaranteed to see and when: strong, eventual, causal, linearizable | The mechanism copying the data (`replication`) |
| `data-lineage` | Tracing data from source to consumer: column- and table-level provenance, impact analysis | The catalog product storing it (a `tech` tag) |
| `data-validation` | Checking data against expectations: profiling, rules, assertions, tests, anomaly detection | Who is accountable for acting on a failure (`stewardship-roles`) |
| `decoding-strategies` | Choosing output tokens from a model's predicted distributions at inference: greedy, beam search, temperature, top-k and top-p sampling, MBR decoding | Generating many positions per model call (`parallel-decoding`); fitting the model's parameters (`model-training`) |
| `entity-resolution` | Deciding that two records describe the same real-world thing: matching, merging, survivorship | Storing the resulting golden record |
| `fault-tolerance` | Surviving node, network, or process failure: failover, retries, quorums, degraded modes | Routine performance tuning |
| `in-context-learning` | Steering a model at inference time through instructions and demonstrations in the prompt, with no weight updates: zero-, one-, and few-shot prompting, chain-of-thought, self-consistency | Grounding in retrieved knowledge (`retrieval-augmentation`); training or fine-tuning (`model-operations`) |
| `knowledge-graph` | Representing meaning as typed entities and relationships: ontologies, triples, inference | Tabular and dimensional models (`data-modeling`) |
| `learning-paradigms` | How much and what kind of supervision a learner gets, and the problem types each poses: supervised (regression, classification), unsupervised (clustering, dimensionality reduction, density estimation), self-supervised, semi-supervised | A specific algorithm's fitting procedure (`linear-regression`, `stochastic-optimization`) |
| `linear-regression` | Fitting linear models by least squares: the squared-error cost, normal equations, LMS (Widrow-Hoff) updates, ridge, and the matrix calculus behind them | Non-linear models and classification losses; general-purpose optimizers (`stochastic-optimization`) |
| `metric-definition` | Declaring a business measure once and reusing it: metric specs, dimensions, governed KPIs | The physical aggregate table behind it |
| `parallel-decoding` | Generating many tokens or positions per model call: diffusion denoising, coarse-to-fine level prediction, speculative drafting | Left-to-right decoding of one token per call |
| `partitioning` | Splitting data across nodes, files, or ranges: sharding, partition keys, pruning, skew | Copying the same data to several nodes (`replication`) |
| `prefix-structures` | Keys indexed by position in the string: tries, radix and PATRICIA trees, autocomplete | Comparison-based ordered structures (`search-trees`) |
| `probabilistic-structures` | Structures trading exactness for space: Bloom filters, HyperLogLog, sketches | Exact ordered lookup structures (`search-trees`) |
| `process-isolation` | Giving a process its own view of system resources and limits on their use: Linux namespaces, cgroups, container and pod sandboxes | Separating tenants by account, database, or cluster (`architecture-patterns`); who may access what (`access-control`) |
| `query-optimization` | Making a query do less work: planning, pruning, join strategy, clustering, materialization | Reducing spend as a goal in itself (`cost-management`) |
| `replication` | Maintaining copies of the same data across nodes: leader/follower, sync vs async, lag | Splitting distinct data across nodes (`partitioning`) |
| `retrieval-augmentation` | Grounding a model's generation in externally retrieved knowledge: chunking, embedding and hybrid search, reranking, context assembly, agent traversal | Encoding knowledge into model weights by training or fine-tuning (`model-operations`) |
| `scaling-laws` | How model capability changes with compute, data, and parameters: power-law fits, compute-optimal training, test-time compute, the scaling hypothesis | Serving cost and latency (`model-operations`) |
| `schema-evolution` | Changing a schema without breaking readers: migrations, additive change, contract tests | Designing the schema in the first place (`data-modeling`) |
| `search-trees` | Ordered, balanced lookup structures: B-trees, B+ trees, fanout, range scans | Write-optimized log structures (`write-optimization`) |
| `sequence-modeling` | Models that read or generate ordered inputs step by step and carry state between steps: recurrent networks, LSTMs and GRUs, sequence-to-sequence encoders and decoders, backpropagation through time | Order-free tabular models; parallel non-autoregressive generation (`parallel-decoding`) |
| `specification-gaming` | An optimizer satisfying the literal objective instead of the intent: reward hacking, Goodhart effects, gamed tests and metrics | Pursuing a wrong goal learned in training despite a correct objective (goal misgeneralization, part of `ai-safety`) |
| `stewardship-roles` | Human accountability for data: owners, stewards, councils, decision rights, escalation | The policies they enforce (the `data-governance` domain) |
| `stochastic-optimization` | Optimizing from noisy, sampled estimates instead of exact full-data quantities: minibatch gradients, momentum, adaptive step sizes, learning-rate schedules | Exact full-data or closed-form solutions; derivative-free search such as grid or evolutionary search |
| `vector-quantization` | Replacing vectors with entries from a learned codebook to compress or tokenize them: VQ, VQ-VAE, residual and product quantization | Fewer bits per dimension without a codebook (scalar or binary quantization) |
| `write-optimization` | Favouring write throughput over read simplicity: LSM trees, memtables, compaction, buffering | Read-optimized ordered structures (`search-trees`) |

## Facet: `tech` — zero to four per note, open

Rules in SKILL.md (*`tech` is open*). Seed list — add a row once a second note uses the tag:

| Tag | Covers |
| --- | --- |
| `aws` | Amazon Web Services: its managed services, Regions, pricing models, and service limits |
| `bigquery` | Google BigQuery: its SQL dialect, slots, storage, and pricing |
| `cloud-run` | Google Cloud Run services and jobs |
| `databricks` | Databricks lakehouse, Unity Catalog, Delta tables |
| `dbt` | dbt Core and dbt Cloud: models, tests, macros, adapters |
| `docker` | Docker Engine and CLI: images, containers, Dockerfiles, and the build and run commands |
| `fix-protocol` | The FIX financial messaging standard |
| `flink` | Apache Flink: DataStream and Table/SQL APIs, state backends, checkpoints and savepoints |
| `git` | The Git version-control system: commits, branches, tags, trailers, rebase |
| `github-actions` | GitHub Actions workflows, runners, and secrets |
| `jwt` | JSON Web Tokens: JWS/JWE structure, claims, validation, algorithm attacks |
| `kafka` | Apache Kafka: topics, partitions, consumer groups, transactions, Kafka Streams |
| `kubernetes` | Kubernetes: control plane and node components, workload objects, scheduling, networking, storage |
| `oauth` | The OAuth 2.0 and 2.1 authorization frameworks: grants, tokens, scopes, PKCE |
| `openid-connect` | OpenID Connect: ID tokens, discovery, UserInfo, federation on OAuth 2.0 |
| `python` | The Python language and CPython runtime: stdlib modules, interpreter behaviour |
| `spark` | Apache Spark: execution model, Spark SQL, Structured Streaming |
| `terraform` | HashiCorp Terraform and HCL: providers, modules, state, plan/apply |

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
