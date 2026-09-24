---
title: CAP Theorem
tags: [data-architecture, databases, transactions, distributed-systems, system-design]
created: 2026-09-24 10:57:07
updated: 2026-09-24 11:08:14
---

# CAP Theorem

The CAP theorem states that a distributed data store cannot simultaneously guarantee **C**onsistency, **A**vailability, and **P**artition tolerance — and since network partitions are a fact rather than an option, the real choice is between remaining consistent or remaining available when one occurs. It is the reason the single-node guarantees of [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] cannot be carried unchanged into a distributed system, and it frames one of the load-bearing decisions in [[concepts/data_architecture|Data Architecture]].

The C in CAP is **linearizability** — every read returns the most recent write across all replicas — which is a different property from the C in ACID, where consistency means the database's declared constraints are not violated. Conflating the two is the most common error in system-design discussions.

## Why It Matters

- **It names a decision you are making whether or not you notice.** Every replicated store behaves *some* way when a node cannot be reached. If you did not choose that behaviour deliberately, you inherited the default — and the default is rarely what the business wants.
- **It bounds what is achievable, not what is convenient.** Gilbert and Lynch proved the trade-off; no amount of engineering removes it. Claims to the contrary are always a redefinition of one of the terms.
- **It exposes where correctness must live.** Choosing availability does not delete the consistency problem, it relocates it into application code as conflict resolution, idempotency, and reconciliation.

## The Three Properties

Brewer stated CAP as a conjecture in 2000; Gilbert and Lynch formalized and proved it in 2002 for an asynchronous network model. Their definitions are stricter than everyday usage, which is the source of most confusion about the theorem.

| Property | Formal meaning | Everyday misreading |
| --- | --- | --- |
| **Consistency** | **Linearizability**: the system behaves as if there were a single copy of the data, and every read sees the most recent completed write | "The data is correct" or "constraints hold" — that is ACID's C |
| **Availability** | **Every request to a non-failing node returns a non-error response**, eventually | "The service has high uptime" or "we have a 99.99% SLA" |
| **Partition tolerance** | The system continues to operate despite **arbitrary loss of messages** between nodes | "The system survives a node crash" — a crash is not a partition |

Two details do most of the work:

- **Availability in CAP is unbounded.** A response that arrives after ten minutes still counts as available. This makes the formal property far stronger than any production definition of availability, and it means real systems sit between the two extremes rather than on them.
- **A partition is a message-loss event, not a machine failure.** A slow network, a saturated link, a misconfigured firewall, or a GC pause long enough to miss heartbeats are all partitions as far as the theorem is concerned. This is why partitions are far more common than the word suggests.

## Why "Pick Two" Is Misleading

CAP is almost always taught as a triangle from which you choose two corners. That framing is wrong in three ways.

**P is not optional.** Networks drop packets. If you choose to abandon partition tolerance, you are not building a different kind of distributed system — you are asserting that partitions never happen, and the system will behave arbitrarily when one does. A "CA" system is a single-node system, or a distributed one with an unexamined failure mode.

**The trade-off only applies during a partition.** When the network is healthy, a well-built system delivers both linearizability and availability. CAP constrains behaviour in a specific, hopefully rare window.

**The choice is not binary or global.** It can be made per operation, per key, per table, or per request. A shopping cart can accept writes during a partition while the payment path refuses them, in the same system.

Brewer's own retrospective, *CAP Twelve Years Later*, makes the sharper point: the useful question is not "which two?" but **"what does the system do while partitioned, and how does it recover afterwards?"** That recovery sequence — detect the partition, enter an explicit degraded mode, then reconcile — is where the real engineering lives, and CAP says nothing about it.

## CP and AP in Practice

During a partition, a node that cannot reach a quorum has exactly two options.

| | **CP — refuse** | **AP — respond anyway** |
| --- | --- | --- |
| Behaviour when partitioned | Minority side rejects or blocks requests | Every side keeps serving reads and writes |
| What the client sees | Errors or timeouts | Success, possibly with stale or divergent data |
| Cost | Downtime for part of the system | Conflicting versions that must be reconciled |
| Reconciliation | None needed — no divergence occurred | Mandatory: last-write-wins, vector clocks, CRDTs, or application merge |
| Appropriate for | Ledgers, inventory, locks, leader election, uniqueness | Carts, sessions, feeds, metrics, caches, presence |
| Typical systems | etcd, ZooKeeper, Consul, Spanner, CockroachDB, HBase, MongoDB (default) | Cassandra, ScyllaDB, DynamoDB, Riak, CouchDB |

Two cautions about that last row. First, most real systems are **tunable rather than categorical**: Cassandra with `QUORUM` reads and writes behaves like a CP system for that query, and MongoDB with `readConcern: local` behaves like an AP one. The label belongs to a configuration, not a product. Second, systems built on consensus (Raft or Paxos) are CP by construction — a minority partition cannot elect a leader, so it cannot make progress, by design.

### Tunable quorums

Dynamo-style stores expose the trade-off directly as three numbers: **N** replicas, **W** acknowledgements required for a write, **R** for a read.

$$R + W > N$$

When that inequality holds, the read and write sets must overlap in at least one replica, so a read is guaranteed to see the latest acknowledged write. Lowering either value buys availability and latency and gives up that guarantee. `W = 1` makes writes fast and durable-ish; `R = 1` makes reads fast and possibly stale; `R = W = 1` is maximally available and promises nothing.

Quorum overlap is a weaker property than linearizability — it says nothing about concurrent writes or read-your-own-writes across sessions — but it is the dial most operators actually turn.

## PACELC: The More Useful Refinement

CAP's blind spot is that partitions are rare, and it says nothing about the other 99.9% of the time. Daniel Abadi's **PACELC** extends it:

> **If** there is a **P**artition, choose between **A**vailability and **C**onsistency; **E**lse, choose between **L**atency and **C**onsistency.

The "else" branch is the one that governs daily operation. Synchronous replication across regions means every write waits for a round trip; asynchronous replication means reads can be stale. There is no partition involved — just the speed of light — and the trade-off is continuous rather than binary.

| System | PACELC classification | Reading |
| --- | --- | --- |
| DynamoDB, Cassandra (default) | **PA/EL** | Stay available when partitioned; favour latency otherwise |
| Spanner, CockroachDB | **PC/EC** | Refuse rather than diverge; pay the latency for consistency always |
| MongoDB (default) | **PC/EC** | Primary-based; consistent, with replication cost on the write path |
| Riak, Cassandra with `ONE` | **PA/EL** | Availability and latency first, reconcile later |

PACELC is the better tool for an architecture review, because the latency-versus-consistency question comes up in every design while the partition question comes up only in incident reviews.

## Consistency Is a Spectrum

CAP presents consistency as a single bit, but there is a whole ladder between linearizable and eventual, and most useful systems live in the middle.

| Model | Guarantee | Cost |
| --- | --- | --- |
| **Linearizable** | Every read sees the latest completed write, globally | Consensus or synchronous replication on every operation |
| **Sequential** | All nodes see operations in the same order, not necessarily real-time order | Cheaper; no global clock needed |
| **Causal** | Causally related operations are seen in order; concurrent ones may differ | Achievable without coordination — the strongest model compatible with availability |
| **Read-your-writes / monotonic reads** | Session-level guarantees only | Cheap; usually sticky routing or client-tracked versions |
| **Eventual** | Replicas converge once writes stop | Free; pushes all conflict handling to the application |

Causal consistency is the interesting boundary: it is provably the strongest model a system can offer while remaining available under partition. Session guarantees are the pragmatic middle ground — a user seeing their own comment appear immediately matters far more to them than global ordering does.

Choosing availability therefore means adopting the mindset described by [[concepts/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]], and accepting the reconciliation machinery that comes with it.

## How Real Systems Position Themselves

- **Spanner** is CP and says so, but achieves near-total availability in practice by owning the network — private fibre, redundant paths — so partitions are rare enough that the CP choice almost never has to be exercised. Its TrueTime clocks provide external consistency at the cost of a commit-wait on every write.
- **CockroachDB and YugabyteDB** take the same position with hybrid logical clocks instead of atomic ones: Raft consensus per range, so a minority partition stalls rather than diverges.
- **Cassandra and DynamoDB** descend from the Dynamo paper and default to availability, exposing `R`/`W` tuning and offering lightweight transactions (Paxos) as an opt-in escape hatch for the few operations that need linearizability. Their write path is a [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]].
- **etcd, ZooKeeper, and Consul** are unambiguously CP — they exist to hold the cluster's truth, so returning stale data would defeat their purpose. Every Kubernetes control plane inherits this.
- **Kafka** is CP for a partition's leader election via the in-sync replica set; `acks=all` with `min.insync.replicas` makes the trade-off explicit, and setting `acks=1` quietly moves it toward AP.

The pattern across all of them: **the guarantee is a per-operation configuration**, and the vendor's category is just its default.

## Common Misreadings

- **"CAP's C is ACID's C."** It is not. CAP's C is linearizability across replicas; ACID's C is constraint enforcement within one transaction. A system can be CP and still violate application invariants, or AP and enforce every `CHECK` constraint locally.
- **"We're CA."** Almost always means "we have not thought about partitions". The only genuine CA system is one that does not replicate.
- **"NoSQL means AP, SQL means CP."** The data model is orthogonal. MongoDB is document-oriented and CP by default; a MySQL cluster with asynchronous replicas is relational and effectively AP.
- **"CAP forbids distributed transactions."** It forbids linearizability *and* total availability simultaneously during a partition. Spanner and CockroachDB provide distributed ACID by choosing the CP side and paying in latency.
- **"Availability means uptime."** CAP's availability is about every non-failing node answering, with no time bound. A CP system with five nines of uptime is still formally unavailable.
- **"The trade-off is permanent."** It applies only while partitioned. Designing the degraded mode and the recovery path matters more than the label.

## Related Concepts

- [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the single-node guarantees CAP constrains once data spans nodes, and the source of the C-versus-C confusion
- [[concepts/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]] — the design philosophy that results from choosing availability
- [[concepts/isolation_levels|Transaction Isolation Levels]] — the same correctness-versus-performance dial, applied to concurrency within one node rather than replication across many
- [[concepts/data_architecture|Data Architecture]] — where the CP/AP decision is made, usually once and close to irreversibly
- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — the storage engine underneath the Dynamo-lineage AP stores
- [[concepts/api_integration_protocols|API and Integration Protocols]] — event-driven integration inherits the same eventual-consistency costs at the system boundary
- [[concepts/data_quality|Data Quality]] — stale or divergent replicas surface downstream as consistency and timeliness failures

## References

- Eric Brewer, *Towards Robust Distributed Systems* (PODC 2000 keynote) — the original conjecture.
- Gilbert and Lynch, ["Brewer's Conjecture and the Feasibility of Consistent, Available, Partition-Tolerant Web Services"](https://dl.acm.org/doi/10.1145/564585.564601), 2002 — the proof.
- Eric Brewer, ["CAP Twelve Years Later: How the 'Rules' Have Changed"](https://www.infoq.com/articles/cap-twelve-years-later-how-the-rules-have-changed/), IEEE Computer, 2012.
- Daniel Abadi, ["Consistency Tradeoffs in Modern Distributed Database System Design"](https://www.cs.umd.edu/~abadi/papers/abadi-pacelc.pdf), IEEE Computer, 2012 — PACELC.
- Martin Kleppmann, ["A Critique of the CAP Theorem"](https://arxiv.org/abs/1509.05393), 2015.
- DeCandia et al., *Dynamo: Amazon's Highly Available Key-Value Store*, SOSP 2007.
- Corbett et al., *Spanner: Google's Globally-Distributed Database*, OSDI 2012.
