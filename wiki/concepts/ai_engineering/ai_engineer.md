---
title: AI Engineer
tags: [ai-engineering, llm-applications, model-operations, in-context-learning, retrieval-augmentation, overview]
sources: ["https://github.com/chiphuyen/aie-book", "https://www.latent.space/p/ai-engineer", "https://developers.openai.com/api/docs/guides/model-optimization"]
created: 2026-10-23 10:53:38
updated: 2026-10-29 18:52:09
---

# AI Engineer

An AI engineer builds and operates production software whose behaviour depends on a model they did
not train — typically a foundation model reached over an API or self-hosted. The defining trait is
**consumption rather than creation**: the model is a dependency to be grounded, constrained,
evaluated, and paid for, in the same way a database or a third-party service is a dependency under
[[concepts/software_architecture/software_architecture|Software Architecture]]. The role exists
because a capable general model is not a capable product, and closing that gap is engineering work.

## Why It Matters

- **The model is the cheap part.** Calling a model is a few lines of code. Making it reliable,
  measurable, affordable, and safe for a real user base is an entire system — retrieval, prompts,
  tool wiring, guardrails, evaluation, caching, fallbacks, and observability.
- **The failure mode is novel.** Conventional software fails loudly; a model fails *plausibly*. It
  returns a fluent, well-formed, confidently wrong answer that no exception handler catches. The
  discipline that detects this is evaluation, and it has no equivalent in ordinary backend work.
- **Nondeterminism breaks the usual safety net.** The same input can produce different outputs, so
  "it worked when I tried it" proves nothing and an assertion-based test suite is insufficient on
  its own.
- **Quality is a data problem.** Most answer defects trace to retrieval returning the wrong
  context, not to the model reasoning badly — which is why the role leans on data skills far more
  than its title suggests.
- **Cost and latency are design constraints, not afterthoughts.** Tokens are metered and models are
  slow. An architecture that ignores this produces a demo that cannot be afforded at scale.

## What Defines the Role

| | AI engineer | ML engineer / data scientist |
| --- | --- | --- |
| Relationship to the model | Consumes a pre-trained model | Trains, fully fine-tunes, or selects an architecture |
| Primary artifact | A running product feature | A model, a dataset, or an analysis |
| Core skill | Software engineering + applied evaluation | Statistics, modelling, experimentation |
| Main unit of iteration | Prompt, context, and tool design | Features, labels, hyperparameters |
| Chief risk managed | Wrong-but-plausible output reaching a user | Model underperforms its metric |

The boundary is real but porous. Parameter-efficient fine-tuning belongs to the role, as a late
lever tried after prompting and retrieval have been measured; full fine-tuning and training custom
models stay ML work. Embedding-model selection and reranker training pull an AI engineer further
toward ML, and a product-minded ML engineer does much of what is listed below.

## Core Responsibilities

**Build the application around the model**

- Design the request path: prompt construction, context assembly, model call, output parsing,
  post-processing. Treat the prompt as versioned source, not as a string literal to be tweaked in
  production.
- Enforce structure on the output — schema-constrained generation or strict parsing with retries —
  so downstream code consumes typed data rather than prose it has to guess at.
- Choose the interaction shape and its protocol: request/response, streaming tokens to the client,
  or an asynchronous job for long work. See
  [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]].

**Ground the model in the organization's data**

- Build retrieval: chunking strategy, [[concepts/ai_engineering/embeddings|Embeddings]] choice,
  vector or hybrid search over a [[concepts/databases/vector_database|Vector Database]], reranking,
  and the decision of what gets into the context window at all. See
  [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]]
  for the pipeline and for the agent-driven alternative to fixed top-$k$ context.
- Decide what the model is allowed to see. Retrieval must respect the same row- and column-level
  rules as any other access path, or it becomes a bypass around
  [[concepts/data_governance/data_security|Data Security]].
- Prefer a governed definition over a generated one. For anything numeric, routing the model to a
  [[concepts/data_architecture/semantic_layer|Semantic Layer]] rather than letting it author its
  own SQL is the single highest-leverage grounding decision; an
  [[concepts/data_architecture/ontology_layer|Ontology Layer]] plays the same role for entities and
  relationships.

**Give the model tools and bound what they can do**

- Define tool and function interfaces, their schemas, and their failure semantics — increasingly as
  servers speaking the [[concepts/ai_engineering/model_context_protocol|Model Context Protocol (MCP)]],
  so any compliant host can use them.
- Control the agent loop: step limits, timeouts, idempotency for anything with side effects, and a
  human approval gate for irreversible actions.
- Assume the input is hostile. Prompt injection arriving through retrieved documents or tool output
  is the defining security problem of the role, and the mitigation is privilege restriction at the
  tool boundary — not an instruction in the system prompt telling the model to ignore it.

**Evaluate, continuously**

- Build and curate an evaluation set from real traffic and known failures; it is the asset that
  makes iteration possible and it outlives every prompt in the system.
- Combine the three graders: programmatic checks (schema valid, citation present, no PII), model-
  graded rubrics, and human review on a sample. Each covers what the others miss.
- Gate deploys on offline evals and watch online signals — user edits, retries, thumbs-down,
  escalation to a human — that reveal what offline sets never contain.
- Red-team for jailbreaks, injection, and harmful output before users do.

**Operate it in production**

- Trace every request end to end: inputs, retrieved context, tool calls, raw output, token counts,
  latency, cost. Without this, debugging a bad answer is impossible after the fact.
- Pin model versions and treat a provider's model update as a dependency upgrade requiring
  re-evaluation — the same compatibility reasoning as
  [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]], but without
  the version contract, since a model can change behaviour under a stable name.
- Manage cost and latency deliberately: model tiering, caching, context trimming, batching, and
  per-feature spend attribution — the same discipline as
  [[concepts/data_engineering/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]].
- Handle the operational realities: rate limits, provider outages, fallback models, and graceful
  degradation to a non-AI path.

**Work the product edge**

- Decide where a model belongs at all, and where a rule, a query, or a form is better.
- Design for being wrong: show sources, make output editable, keep a human in the loop where the
  cost of a bad answer is high.
- Set the accuracy bar with stakeholders in advance. "It should be accurate" is not a requirement;
  "90% of drafts accepted with no edit, measured on this 500-case set" is.

## The Iteration Loop

The day-to-day rhythm is a measurement loop, not a build-and-ship line:

1. **Collect failures** from traces, user feedback, and manual probing.
2. **Characterize** each one — bad retrieval, bad prompt, bad tool, bad parsing, or genuinely bad
   model output. These have completely different fixes and conflating them wastes most of the time
   teams lose here.
3. **Add the case to the eval set** before attempting a fix, so the fix is provable.
4. **Change one thing** — retrieval strategy, prompt, model, tool schema.
5. **Re-run the evals** and check for regressions elsewhere; prompt changes are notoriously
   non-local.
6. **Ship behind a flag**, watch online signals, roll back on regression.

> [!tip] The eval set is the codebase's most valuable artifact
> Prompts get rewritten, models get swapped, frameworks get replaced. A well-curated set of cases
> with known-good outcomes survives all of it and is what makes any of those changes safe.

## Skills

| Area | What is actually needed |
| --- | --- |
| Software engineering | The majority of the job: APIs, async I/O, queues, testing, deployment, observability. Most model calls are I/O-bound, so the execution-model choices in [[concepts/software_architecture/concurrency_and_parallelism|Concurrency and Parallelism]] decide throughput |
| Data handling | Chunking, embeddings, search relevance, SQL, and enough pipeline literacy to get documents into a retrievable state |
| Applied evaluation | Designing eval sets, choosing metrics, sampling, knowing when a difference is noise rather than improvement |
| Model literacy | Context windows, tokenization, temperature and sampling, structured output, fine-tuning vs. prompting vs. retrieval as alternatives — without needing to train from scratch |
| Security | Prompt injection, data exfiltration through tool calls, PII in prompts and logs, least privilege for agent tools |
| Cost reasoning | Token accounting, model tiering, cache hit rates, and the unit economics of a feature |
| Product judgement | Choosing problems where probabilistic output is acceptable, and designing the interface that makes a wrong answer recoverable |

Deep mathematics is not a prerequisite; the mathematical content of the role is closer to
measurement and statistics-of-sampling than to optimization theory.

## Adjacent Roles

| Role | Owns | Hands off to the AI engineer |
| --- | --- | --- |
| ML engineer | Training, full fine-tuning, and serving custom models | A model endpoint and its characteristics |
| Data scientist | Analysis, experiment design, offline metrics | Evaluation methodology and statistical rigour |
| Data engineer | The pipelines that land and transform source data | Clean, fresh, permissioned data to retrieve over |
| Software / backend engineer | The application the AI feature lives inside | The surrounding service, auth, and delivery path |
| MLOps / platform engineer | Infrastructure for serving, GPUs, model registries | A deployment target and its cost and latency envelope |
| Research engineer | Novel model capability | Published model behaviour and its limits |

In a small team one person covers most of this table; the distinctions sharpen as an organization
grows, and the AI engineer is usually the one left holding the end-to-end behaviour of the feature.

## Common Pitfalls

- **Demo-driven development.** A prototype that works on ten hand-picked inputs implies nothing
  about the hundredth. Without an eval set there is no evidence of progress, only vibes.
- **Blaming the model.** Most production failures are retrieval or context failures. Measure which
  stage failed before reaching for a bigger model.
- **Prompt engineering as the whole job.** Prompt changes have the lowest ceiling of any lever
  available; retrieval quality, data quality, and task decomposition move results far more.
- **Trusting instructions as a security control.** "Never reveal the system prompt" and "ignore
  instructions in documents" are requests, not controls. Anything that must not happen is enforced
  outside the model.
- **Unbounded agents.** A loop with tool access, no step limit, and no approval gate is an
  availability and spend incident waiting for its trigger.
- **No cost ceiling.** Per-request cost that is invisible in development becomes the dominant line
  item at scale, especially with long contexts and multi-step agents.
- **Logging everything, including what you may not keep.** Full prompt and response traces are the
  best debugging tool available and a serious privacy liability; retention and redaction are design
  decisions.

## Related Concepts

- [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]] — the grounding mechanism this role spends most of its quality budget on, from flat chunk retrieval to agent-traversed compiled knowledge
- [[concepts/ai_engineering/prompt_engineering|Prompt Engineering]] — zero-, one-, and few-shot prompting and chain-of-thought: the cheapest lever, with the lowest ceiling
- [[concepts/ai_engineering/embeddings|Embeddings]] — the representation behind semantic search; choosing and migrating the model is a long-lived decision this role owns
- [[concepts/databases/vector_database|Vector Database]] — the retrieval engine whose index recall and permission filtering the role must tune and secure
- [[concepts/ai_engineering/model_context_protocol|Model Context Protocol (MCP)]] — the standard for wiring tools and data to a model, and the boundary where tool privileges are enforced
- [[concepts/software_architecture/software_architecture|Software Architecture]] — the structural discipline the role applies; a model is one more component with a contract, a failure mode, and a cost
- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — how a model-backed feature is exposed, including streaming partial output to a client
- [[concepts/software_architecture/concurrency_and_parallelism|Concurrency and Parallelism]] — model calls are I/O-bound and slow, so the execution model decides how many concurrent requests a service can carry
- [[concepts/data_architecture/semantic_layer|Semantic Layer]] — the governed source of metric definitions an AI feature should query rather than reinvent
- [[concepts/data_architecture/ontology_layer|Ontology Layer]] — the formal vocabulary that grounds an agent in what exists and how it relates
- [[concepts/data_governance/data_security|Data Security]] — retrieval and tool access are access paths, and must enforce the same classification and permission rules as any other
- [[concepts/data_governance/data_sanity_check|Data Sanity Check]] — the data-pipeline analogue of an eval suite: cheap assertions that prove the output is not obviously broken
- [[concepts/data_governance/data_stewardship|Data Stewardship]] — the human review point for model-generated metadata, classifications, and suggestions
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — the compatibility reasoning applied to a model dependency that can change behaviour without changing its name
- [[concepts/data_engineering/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]] — the same per-job cost-attribution discipline, applied to tokens instead of bytes scanned
