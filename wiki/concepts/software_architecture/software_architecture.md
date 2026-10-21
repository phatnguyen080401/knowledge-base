---
title: Software Architecture
tags: [software-architecture, architecture-patterns, overview]
created: 2026-10-20 16:09:59
updated: 2026-10-21 15:02:01
---

# Software Architecture

Software architecture is the set of structural decisions about a software system — how it is divided into components, how those components communicate, and which quality attributes the division optimizes for — that are expensive to reverse once code depends on them. It is the general-purpose counterpart to [[concepts/data_architecture/data_architecture|Data Architecture]]: the same discipline applied to behaviour and interfaces rather than to the data a platform stores.

## Why It Matters

- **Cost of change.** Architecture determines which future changes are cheap and which require rewriting. A decision that takes an afternoon before the first release can take a year afterwards.
- **It encodes trade-offs, not best practices.** Every style buys one quality attribute by spending another — independent deployability is paid for with network calls, operational complexity, and the consistency problems of [[concepts/databases/cap_theorem|CAP Theorem]].
- **It constrains the team, and vice versa.** Conway's law: a system's module boundaries tend to mirror the communication boundaries of the organization that builds it. Choosing an architecture that contradicts the org chart means fighting the org chart.
- **It is where non-functional requirements live.** Latency, availability, security posture, and auditability are rarely satisfiable by local code changes; they are properties of the structure.

## Architecture vs. Design

The line is one of reversibility and scope, not of abstraction level:

| | Architecture | Design |
| --- | --- | --- |
| Scope | Relationships *between* components | Internals *of* a component |
| Reversibility | Expensive — other components depend on it | Cheap — change is local |
| Examples | Service boundaries, synchronous vs. event-driven communication, data ownership, deployment unit | Class structure, algorithm choice, naming, local error handling |

A useful test: if changing the decision requires coordinating with another team or migrating persisted state, it is architectural.

## Quality Attributes

Architecture is evaluated against quality attributes (the "-ilities"), which trade against one another. The job is to decide which ones matter for *this* system, and to accept that the rest are being sacrificed.

| Attribute | Question it answers | Commonly traded against |
| --- | --- | --- |
| Performance / latency | How fast is a single operation? | Scalability, consistency |
| Scalability | What happens at 10× load? | Simplicity, cost |
| Availability | What fraction of requests succeed during failure? | Consistency (see CAP) |
| Consistency | Do readers see the latest write? | Availability, latency |
| Modifiability | How cheap is a typical change? | Performance (indirection costs) |
| Testability | Can a component be verified in isolation? | Deployment simplicity |
| Observability | Can you explain production behaviour after the fact? | Cost, throughput |
| Security | Who can reach what, and is it provable? | Convenience, latency |

Attributes must be stated as measurable scenarios ("p99 under 200 ms at 5k rps"), not as adjectives. "Must be scalable" is not a requirement; it is a wish.

## Architectural Styles

| Style | Shape | Strengths | Costs |
| --- | --- | --- | --- |
| Layered / n-tier | Horizontal layers (UI, logic, data), each depending downward | Familiar, easy to staff, simple deployment | Changes cut across every layer; layers often leak |
| Modular monolith | One deployment unit, enforced internal module boundaries | Monolith's simplicity with real seams for later extraction | Boundaries erode without discipline or tooling |
| Microservices | Independently deployable services, each owning its data | Independent deploy and scale, team autonomy, fault isolation | Distributed failure modes, no cross-service transactions, heavy operational burden |
| Event-driven | Components react to events on a broker | Loose coupling, natural fan-out, buffers load spikes | Eventual consistency, hard debugging, event schema becomes a contract |
| Hexagonal / ports and adapters | Domain core surrounded by adapters to the outside world | Domain testable without infrastructure, swappable I/O | Indirection overhead; over-applied on simple systems |
| Pipes and filters | Stages chained by streams | Composable, parallelizable; the shape most data pipelines take | Per-stage latency, back-pressure handling |
| Serverless / function-based | Functions deployed and scaled per request | No capacity management, pay-per-use | Cold starts, vendor coupling, state must live elsewhere |

Styles compose. A modular monolith publishing events, or a handful of services each internally hexagonal, is far more common than a textbook-pure example of any one style.

> [!tip] Start with the simplest structure that can satisfy the stated quality attributes
> A modular monolith with honest boundaries can be decomposed later; a premature microservice split has to be re-merged, which nobody ever does.

## Decomposition and Boundaries

- **Cohesion over size.** A component should have one reason to change. "Too big" is not a defect by itself; serving two unrelated reasons to change is.
- **Coupling is the real currency.** Afferent coupling (who depends on me) determines how expensive my changes are; efferent coupling (who I depend on) determines how fragile I am.
- **Own your data.** A component that shares a database table with another is not independent, whatever the deployment diagram says. Shared storage is the most common hidden coupling.
- **Boundaries follow the domain.** Bounded contexts from domain-driven design give a decomposition that survives, because terms mean one thing inside a boundary and are explicitly translated at the edge — the same discipline the [[concepts/data_architecture/ontology_layer|Ontology Layer]] applies to vocabulary.
- **Communication across a boundary is a contract.** Once another component depends on it, the interface is subject to [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] choices and the compatibility rules of [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]].

## Cross-Cutting Decisions

- **Synchronous or asynchronous.** The single most consequential inter-component choice: a synchronous call binds the caller's availability to the callee's, an event does not. The same question recurs *inside* a component as the choice of execution model — see [[concepts/software_architecture/concurrency_and_parallelism|Concurrency and Parallelism]].
- **Contract evolution.** Breaking changes must be deliberate and announced. A MAJOR version bump, a parallel `/v2` endpoint, or a new event type with a deprecation window — not a silent field change.
- **Failure handling.** Timeouts, retries with jitter, circuit breakers, and idempotency keys belong to the architecture; added per-call after the fact, they never cover the whole surface.
- **Security posture.** Authentication, authorization, and encryption at each boundary, designed in rather than bolted on. See [[concepts/data_governance/data_security|Data Security]].
- **Deployment and release.** How a change reaches production — immutable artifacts, environment promotion, rollback by redeploying an older tag — is architectural; [[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]] is one worked example of that pattern.
- **Observability.** Correlation IDs, structured logs, and traces must cross component boundaries, or debugging stops at the first hop.

## Documenting Decisions

- **Architecture Decision Records (ADRs).** One short file per decision: context, the options considered, the decision, and its consequences. Immutable once accepted — a reversal is a new ADR that supersedes the old one. ADRs preserve *why*, which diagrams never do.
- **C4 model.** Four nested diagram levels — system context, container, component, code — so each audience reads one level rather than one diagram trying to serve everyone.
- **Fitness functions.** Automated checks that assert an architectural property still holds: dependency-direction tests, latency budgets in CI, bundle-size limits. Architecture that is not tested decays into whatever the code happens to do.
- **Generated diagrams.** The only diagram guaranteed to be current is one derived from the system itself — from code, from infrastructure state, or from a tool where the design *is* the deployable artifact, as [[concepts/devops/brainboard|Brainboard]] attempts for cloud infrastructure.

## Common Pitfalls

- **Resume-driven design.** Choosing a style for its novelty rather than for a quality attribute the system actually needs.
- **The distributed monolith.** Services split at the deployment level but still released together and sharing a database — all the operational cost of microservices, none of the independence.
- **Ignoring the data.** Service boundaries drawn without deciding who owns which entity produce either chatty cross-service reads or silent duplication; this is where software architecture hands off to [[concepts/data_governance/master_data_management|Master Data Management (MDM)]].
- **Treating the diagram as the architecture.** The architecture is what the running system does. An undocumented workaround in production is an architectural fact; a box on a slide may not be.
- **Deferring nothing, or deferring everything.** Decisions that are cheap to reverse should be delayed until the last responsible moment; decisions that persist state or publish a contract should not be made casually early.

## Related Concepts

- [[concepts/data_architecture/data_architecture|Data Architecture]] — the same structural discipline applied to a data platform; the two constrain each other at every boundary where software produces or consumes data
- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — how the components chosen here actually talk to one another
- [[concepts/software_architecture/concurrency_and_parallelism|Concurrency and Parallelism]] — the execution model inside a component: threads, processes, or an event loop, and which races each one admits
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — the compatibility contract that makes an interface safe to depend on across releases
- [[concepts/software_architecture/fix_protocol|FIX Protocol (Financial Information eXchange)]] — a long-lived industry standard, and a case study in what interface decisions cost decades later
- [[concepts/databases/cap_theorem|CAP Theorem]] — the hard limit on what a distributed architecture can promise during a network partition
- [[concepts/data_governance/data_security|Data Security]] — the controls each architectural boundary has to enforce
- [[concepts/devops/brainboard|Brainboard]] — a tool overview: visual cloud-infrastructure design that generates the Terraform, aimed at the diagram-versus-reality gap described above

## References

- [Architecture Decision Records](https://adr.github.io/) — templates and tooling for recording decisions
- [The C4 model](https://c4model.com/) — the four-level diagram notation for software architecture
