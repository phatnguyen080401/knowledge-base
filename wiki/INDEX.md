# Index

Every page in `wiki/concepts/`, one group per folder, each with a one-line summary for shortlisting.

## AI Engineering

Folder: `wiki/concepts/ai_engineering/`

- [[concepts/ai_engineering/ai_engineer|AI Engineer]] — hub: the role that ships products on models it did not train — responsibilities, the iteration loop, skills, and boundaries with ML, data, and backend work.
- [[concepts/ai_engineering/chain_of_thought|Chain-of-Thought (CoT) Prompting]] — reasoning as a latent variable, few-/zero-shot CoT, Auto-CoT, self-consistency voting, least-to-most, tree of thoughts, PAL, reasoning models, faithfulness.
- [[concepts/ai_engineering/digital_superintelligence|Digital Superintelligence]] — hub: AGI vs. ASI, speed/collective/quality forms, paths, takeoff, orthogonality and instrumental convergence, alignment research, lab frameworks, key debates.
- [[concepts/ai_engineering/embeddings|Embeddings]] — text-to-vector pipeline, contrastive training, similarity metrics, dense vs. sparse vs. multi-vector, bi- vs. cross-encoders, Matryoshka and quantization.
- [[concepts/ai_engineering/model_context_protocol|Model Context Protocol (MCP)]] — host/client/server architecture, tools/resources/prompts, the stateless 2026-07-28 core, transports, OAuth 2.1 authorization, security threats, version history.
- [[concepts/ai_engineering/prompt_engineering|Prompt Engineering]] — prompt anatomy, zero- vs. one- vs. few-shot, what demonstrations teach, a chain-of-thought summary, and the limits of prompting.
- [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]] — indexing and query pipeline, chunking, contextual retrieval, evaluation; multi-hop limits of flat retrieval; retrieval-as-reasoning over a compiled wiki.

### AGI

Folder: `wiki/concepts/ai_engineering/agi/`

- [[concepts/ai_engineering/agi/artificial_general_intelligence|Artificial General Intelligence (AGI)]] — history, competing definitions, DeepMind's Levels of AGI, tests and benchmarks (ARC-AGI, task horizons), scaling laws and test-time compute, open gaps.

### Alignment

Folder: `wiki/concepts/ai_engineering/alignment/`

- [[concepts/ai_engineering/alignment/ai_alignment|AI Alignment]] — outer vs. inner alignment, failure modes (specification gaming, sycophancy, deceptive alignment), RLHF/RLAIF/DPO math, scalable oversight, interpretability, AI control.

## Data Architecture

Folder: `wiki/concepts/data_architecture/`

- [[concepts/data_architecture/data_architecture|Data Architecture]] — hub: the three model levels, platform layers, reference patterns, table formats, serving-layer modelling, and how decisions get recorded.
- [[concepts/data_architecture/ontology_layer|Ontology Layer]] — the formal domain vocabulary: classes, properties, axioms, and why inference separates it from a schema.
- [[concepts/data_architecture/semantic_layer|Semantic Layer]] — the governed translation tier between warehouse models and consumers: entities, metrics, grain, access rules.
- [[concepts/data_architecture/semantic_layer_vs_ontology_layer|Semantic Layer vs. Ontology Layer]] — measurement contract vs. vocabulary contract, how the two compose, and which to reach for.

## Data Engineering

Folder: `wiki/concepts/data_engineering/`

- [[concepts/data_engineering/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]] — per-job cost attribution from `INFORMATION_SCHEMA`, plus the controls those measurements justify.
- [[concepts/data_engineering/stateful_vs_stateless_stream_processing|Stateful vs. Stateless Stream Processing]] — comparison: operator kinds, hidden state, keyed/broadcast state, backends, co-partitioning, rescaling, watermarks, checkpoints, exactly-once; Flink, Kafka Streams, Spark.
- [[concepts/data_engineering/workflow_orchestration|Workflow Orchestration]] — scheduling, sequencing, retrying, and backfilling pipeline tasks as a cross-system DAG; Airflow, Dagster. **Stub.**

### dbt (Data Build Tool)

Folder: `wiki/concepts/data_engineering/dbt/`

- [[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] — models, `ref()`/`source()`, tests, macros, materializations, project layering, governance features, Core vs. Cloud.
- [[concepts/data_engineering/dbt/dbt_bigquery_adapter|dbt-bigquery Adapter]] — `profiles.yml` parameters, all four auth methods, BigQuery model configs, incremental strategies, cost control.
- [[concepts/data_engineering/dbt/dbt_databricks_adapter|dbt-databricks Adapter]] — `profiles.yml` parameters, PAT and OAuth M2M/U2M flows, multiple compute targets, common connection failures.
- [[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]] — a worked template: Dockerfile, Workload Identity, both workflows, state deferral, scheduling.

### Apache Kafka

Folder: `wiki/concepts/data_engineering/kafka/`

- [[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]] — tool overview: the partitioned commit log — offsets, ISR and `acks`, consumer groups, delivery semantics, compaction, and what Kafka is not.

### Apache Spark

Folder: `wiki/concepts/data_engineering/spark/`

- [[concepts/data_engineering/spark/apache_spark|Apache Spark]] — tool overview: driver/executor model, lazy DAG and shuffle cost, Catalyst and AQE, partitions and skew, caching, Structured Streaming, and when not to use it.

## Data Governance

Folder: `wiki/concepts/data_governance/`

- [[concepts/data_governance/data_governance|Data Governance]] — hub: the operating model for data — principles, roles, frameworks, and the pillars it coordinates.
- [[concepts/data_governance/data_quality|Data Quality]] — the six dimensions and their checks, where defects originate, and the measure-remediate lifecycle.
- [[concepts/data_governance/data_sanity_check|Data Sanity Check]] — cheap aggregate boundary checks: anatomy, sources of expectations, the cost ladder, standard assertions, a worked orders-pipeline suite, failure response.
- [[concepts/data_governance/data_security|Data Security]] — classification, access control models, encryption and key management, the de-identification techniques, and the pipeline-specific leaks.
- [[concepts/data_governance/data_stewardship|Data Stewardship]] — who is accountable: steward vs. owner vs. custodian, operating models, workflows, and metrics.
- [[concepts/data_governance/master_data_management|Master Data Management (MDM)]] — golden records, entity resolution and survivorship, the four implementation styles, and hierarchy management.
- [[concepts/data_governance/metadata_management|Metadata Management]] — the four metadata types, glossary vs. dictionary vs. catalog, lineage capture methods, and active vs. passive metadata.

## Data Structures

Folder: `wiki/concepts/data_structures/`

- [[concepts/data_structures/data_structures_algorithms|Data Structures and Algorithms]] — hub: the read/write/space trade-off that separates the structures below.
- [[concepts/data_structures/b_plus_tree|B+ Tree]] — all records in chained leaves; the index structure shipped by virtually every relational database.
- [[concepts/data_structures/b_tree|B-Tree]] — the baseline disk-oriented balanced tree every other index structure is compared against.
- [[concepts/data_structures/bloom_filter|Bloom Filter]] — probabilistic set membership: no false negatives, tunable false positives, and the sizing formulas.
- [[concepts/data_structures/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — write-optimized storage: memtable, SSTables, compaction, and the read amplification it trades for.
- [[concepts/data_structures/trie|Trie (Prefix Tree)]] — prefix-keyed retrieval, when position-in-string beats comparison, and the compressed variants.

## Databases

Folder: `wiki/concepts/databases/`

- [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the four guarantees, the mechanism behind each, and where they break down once distributed.
- [[concepts/databases/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]] — session guarantees, tunable quorums, conflict resolution, and what BASE hands to the application.
- [[concepts/databases/cap_theorem|CAP Theorem]] — what C, A, and P actually mean, why "pick two" is wrong, and the PACELC refinement.
- [[concepts/databases/distributed_consensus|Distributed Consensus]] — nodes agreeing on one value or log despite failures; Paxos, Raft, majority quorums, leader election. **Stub.**
- [[concepts/databases/isolation_levels|Transaction Isolation Levels]] — the six anomalies with worked interleavings, the level matrix, and what each engine's level names really mean.
- [[concepts/databases/multiversion_concurrency_control|Multiversion Concurrency Control (MVCC)]] — row versions and snapshots so readers and writers never block each other. **Stub.**
- [[concepts/databases/real_time_analytics_database|Real-Time Analytics Database]] — the five requirements, vs. OLTP/warehouse/stream processing, columnar and LSM-style ingestion, skipping indexes, pre-aggregation; ClickHouse, Druid, Pinot.
- [[concepts/databases/vector_database|Vector Database]] — exact vs. approximate nearest-neighbour search, HNSW/IVF/PQ/DiskANN indexes, filtering, hybrid search with RRF, scaling, the product landscape, and pgvector.
- [[concepts/databases/write_ahead_log|Write-Ahead Log (WAL)]] — log-before-write for crash recovery, atomicity, durability, and log-shipping replication. **Stub.**

## DevOps

Folder: `wiki/concepts/devops/`

- [[concepts/devops/brainboard|Brainboard]] — tool overview: visual multi-cloud design generating Terraform/OpenTofu, with CI/CD, drift detection, and policy and cost scanning. Vendor-sourced, unverified.
- [[concepts/devops/observers|Observers]] — hub: logs, metrics, and traces, how to correlate them, golden signals and RED/USE, and the open-source stack per signal.
- [[concepts/devops/renovate_docs|Renovate]] — tool overview: automated dependency-update PRs — platform/manager/datasource/versioning modules, onboarding, presets, grouping, schedules, automerge, Dependency Dashboard, vs. Dependabot.
- [[concepts/devops/trivy|Trivy]] — tool overview: open-source scanner for CVEs, IaC misconfiguration, secrets, and licences across images, repos, clusters, and SBOMs; where the CI gate belongs.

### Kubernetes

Folder: `wiki/concepts/devops/kubernetes/`

- [[concepts/devops/kubernetes/kubernetes|Kubernetes]] — hub: control plane and nodes, reconciliation, workload/network/storage objects, scheduling and QoS, probes, pod termination, rollouts, autoscaling, RBAC, CRDs and operators.
- [[concepts/devops/kubernetes/kubelet_tls_bootstrapping|Kubelet TLS Bootstrapping]] — joining nodes with bootstrap tokens and CSRs, discovery and CA pinning, rotation, kubelet client vs. serving certificates, securing port 10250.
- [[concepts/devops/kubernetes/kubernetes_components|Kubernetes Components]] — API server pipeline, etcd quorum, scheduler plugins, controllers, kubelet, CRI/CNI/CSI, kube-proxy, add-ons, HA, failure modes, debugging.
- [[concepts/devops/kubernetes/pod_sandbox|Pod Sandbox (Pause Container)]] — shared network/IPC/UTS namespaces, the pause container, sandbox lifecycle and SandboxChanged, inspecting with crictl.
- [[concepts/devops/kubernetes/static_pod_vs_normal_pod|Static Pod vs. Normal Pod]] — kubelet file source vs. API, mirror pods, editing the control plane, vs. DaemonSets; hidden static pods summarized, detailed in their own note.
- [[concepts/devops/kubernetes/veth_pair|Virtual Ethernet (veth) Pair]] — how CNI plugins wire pods with veth pairs, bridge vs. routed vs. eBPF, same- and cross-node packet paths, MTU, tracing a pod's interface.

#### Security

Folder: `wiki/concepts/devops/kubernetes/security/`

- [[concepts/devops/kubernetes/security/kubernetes_security|Kubernetes Security]] — hub: attack-surface map (API server, etcd, kubelet API, bootstrap tokens, static pod directory) and a table of attack-technique notes.
- [[concepts/devops/kubernetes/security/hidden_static_pods|Hidden Static Pods]] — persistence via a static pod in a non-existent namespace: why only static pods, the attack flow, node-vs-API detection, mitigation.

### Logging

Folder: `wiki/concepts/devops/logging/`

- [[concepts/devops/logging/elasticsearch|Elasticsearch]] — tool overview: Lucene-based log store in the Elastic Stack (ELK) — shards, data streams, ILM, ECS, mapping explosion, cost vs. Loki, OpenSearch fork.

### Metrics

Folder: `wiki/concepts/devops/metrics/`

- [[concepts/devops/metrics/prometheus|Prometheus]] — tool overview: pull-based metrics and TSDB — metric types, label cardinality, service discovery, exporters, Alertmanager, HA and long-term storage.

### Tracing

Folder: `wiki/concepts/devops/tracing/`

- [[concepts/devops/tracing/jaeger|Jaeger]] — tool overview: distributed tracing — spans, context propagation, collector/storage/UI, sampling strategies, OpenTelemetry, vs. Tempo and Zipkin.

## Identity and Access

Folder: `wiki/concepts/identity_and_access/`

- [[concepts/identity_and_access/authentication|Authentication]] — AuthN vs. AuthZ, factors and MFA, NIST 800-63B-4 assurance levels and password rules, passkeys and phishing resistance, sessions, workload auth, attacks.
- [[concepts/identity_and_access/authorization|Authorization]] — PEP/PDP architecture, ACL vs. RBAC vs. ABAC vs. ReBAC, least privilege, OWASP A01 broken-access-control failures, delegated scopes.
- [[concepts/identity_and_access/json_web_token|JSON Web Token (JWT)]] — structure and registered claims, JWS vs. JWE algorithms, JWKS, the RFC 8725 validation checklist, algorithm attacks, revocation.
- [[concepts/identity_and_access/oauth|OAuth (Open Authorization)]] — roles, grant types, authorization code with PKCE, bearer vs. sender-constrained tokens, RFC 9700 baseline, OAuth 2.1, extension RFCs.
- [[concepts/identity_and_access/openid_connect|OpenID Connect (OIDC)]] — identity layer on OAuth 2.0: ID token claims and validation, flows, discovery, ID vs. access token, workload OIDC tokens.
- [[concepts/identity_and_access/single_sign_on|Single Sign-On (SSO)]] — IdP and SP roles, SAML 2.0 vs. OIDC, SP- vs. IdP-initiated flows, SAML validation, SCIM provisioning, logout.

## Software Architecture

Folder: `wiki/concepts/software_architecture/`

- [[concepts/software_architecture/software_architecture|Software Architecture]] — hub: quality attributes, architectural styles and their costs, decomposition, cross-cutting decisions, ADRs and C4.
- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — REST, GraphQL, gRPC, SOAP, webhooks, SSE, WebSockets, MQTT, AMQP, and EDI, organized by interaction style.
- [[concepts/software_architecture/concurrency_and_parallelism|Concurrency and Parallelism]] — threads vs. processes vs. the event loop, I/O- vs. CPU-bound work, race conditions with worked interleavings, synchronization primitives, and deadlock.
- [[concepts/software_architecture/fix_protocol|FIX Protocol (Financial Information eXchange)]] — session vs. application layer, the order lifecycle, versions and encodings, and its ingestion pitfalls.
- [[concepts/software_architecture/global_interpreter_lock|Global Interpreter Lock (GIL)]] — why CPython serializes bytecode, when the lock is released, what it costs, and the four ways around it including free-threaded builds.
- [[concepts/software_architecture/idempotency|Idempotency]] — operations safe to repeat: retries, idempotency keys, at-least-once delivery. **Stub.**
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — the increment rules, precedence algorithm, pre-release suffixes, and how it surfaces in data tooling.

## Version Control

Folder: `wiki/concepts/version_control/`

- [[concepts/version_control/git|Git]] — hub: the four object types and four areas, then commands by task — recording, inspecting, branching, merging, rebasing, undoing, remotes, tags, large repos.
- [[concepts/version_control/conventional_commits|Conventional Commits]] — the `<type>[scope]: <description>` format, specified and conventional types, breaking-change signalling, and the mapping onto SemVer releases.

### GitLab

Folder: `wiki/concepts/version_control/gitlab/`

- [[concepts/version_control/gitlab/gitlab_repository_security|GitLab Repository Security]] — hardening a project: protected branches and tags, approvals, push rules, merge-request controls, CI/CD variable and runner isolation, scanners, leaked secrets.
