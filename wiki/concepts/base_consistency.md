---
title: BASE (Basically Available, Soft State, Eventual Consistency)
tags: [data-architecture, databases, transactions]
created: 2026-09-24 10:57:07
updated: 2026-09-24 11:16:13
---

# BASE (Basically Available, Soft State, Eventual Consistency)

BASE is the design philosophy that deliberately gives up the strict guarantees of [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] in exchange for availability and horizontal scale: the system stays responsive under partition and load (**basically available**), replicas may disagree at any given moment (**soft state**), and they converge once writes stop propagating (**eventual consistency**).

It is the practical consequence of choosing availability over consistency in the [[concepts/cap_theorem|CAP Theorem]], and it moves correctness out of the database and into the application — which must then tolerate stale reads, resolve conflicting writes, and make its operations idempotent. Adopting it is a [[concepts/data_architecture|Data Architecture]] decision, not a database setting.

## Why It Matters

- **It is a transfer of responsibility, not a removal of one.** Nothing about BASE makes conflicting writes disappear; it decides that the *application* resolves them instead of the database preventing them. Teams that adopt it without building that machinery ship silent data loss.
- **It is what makes horizontal scale cheap.** Every guarantee ACID provides requires coordination, and coordination is the thing that does not scale across regions. Dropping it is why Dynamo-lineage stores add capacity linearly.
- **Most systems need both.** The interesting design work is drawing the line — which operations tolerate staleness and which do not — rather than picking one philosophy for the whole system.

## The Three Properties

The acronym is a deliberate chemistry pun on ACID, coined by Eric Brewer and Armando Fox around 1997 and popularized by Amazon's 2007 Dynamo paper. It is a description of a posture, not a formal specification — unlike ACID, no property here has a precise definition you can test against.

| Property | Meaning | What it costs you |
| --- | --- | --- |
| **Basically Available** | Every request gets a response, though it may be stale, partial, or degraded | You cannot trust a read to be current |
| **Soft state** | Replica state may change without new input, as replication and repair converge it | "The current value" is not a well-defined question |
| **Eventual consistency** | If writes stop, all replicas converge on the same value | No bound on when; no guarantee about *which* value |

### Basically available

The system answers rather than errors. That answer may come from a replica that has not seen recent writes, may omit a failed shard, or may be a cached fallback. The contract is *a response*, not *the right response*.

In practice this shows up as graceful degradation: a recommendations panel that renders yesterday's results when its service is down, or a feed that omits the last few seconds of posts. The degraded mode is a designed feature, which is the part teams usually skip.

### Soft state

In an ACID system, stored state changes only when a transaction changes it. Under BASE, a replica's state also changes as a consequence of background processes — replication catching up, read repair, anti-entropy, hinted handoff being replayed, TTLs expiring. Read the same key from two nodes a millisecond apart and you may legitimately get two answers, with neither being wrong.

### Eventual consistency

The formal guarantee is weak to the point of being almost vacuous: *if no new writes are made, all replicas eventually converge*. It is a **liveness** property with no time bound, and "writes stop" never happens in a live system.

What it deliberately omits: how long convergence takes, what a client sees in the meantime, and which value wins when replicas disagree. Those three questions are the entire engineering problem, and none of them is answered by the words "eventually consistent". That is why the useful conversation is always about the **specific** guarantees layered on top.

## The Guarantees You Actually Want

Raw eventual consistency is unusable for most user-facing features — a user who posts a comment and does not see it assumes the product is broken. Session guarantees fill the gap without requiring global coordination:

| Guarantee | Promise | Typical implementation |
| --- | --- | --- |
| **Read-your-writes** | You always see your own writes | Sticky routing to one replica, or the client sends its last-seen version |
| **Monotonic reads** | You never see time move backwards | Pin a session to a replica, or track a high-water mark |
| **Monotonic writes** | Your writes apply in the order you issued them | Per-session sequence numbers |
| **Consistent prefix** | You never see an effect without its cause | Ordered replication of a partition's log |
| **Causal consistency** | Causally related operations are seen in order everywhere | Vector clocks or dependency tracking |

Causal consistency is the ceiling: it is provably the strongest model a system can provide while remaining available during a partition. Everything above it requires coordination and therefore forfeits the A in CAP.

## Tunable Consistency

Dynamo-style stores do not force a single point on the spectrum; they expose it per query as **N** replicas, **W** write acknowledgements, and **R** read responses.

$$R + W > N$$

When that holds, the read and write sets overlap, so a read sees the latest acknowledged write. Setting `R = W = 1` is maximally available and maximally stale. The same table can serve both: `QUORUM` for a balance check, `ONE` for a page-view counter.

The background machinery that makes convergence actually happen is worth knowing by name, because it is what appears in the metrics when things go wrong:

- **Hinted handoff** — a coordinator that cannot reach a replica stores the write locally and replays it when the node returns. Keeps writes available; delays convergence.
- **Read repair** — a read that finds divergent replicas writes the winning value back. Convergence as a side effect of traffic, so cold keys stay divergent indefinitely.
- **Anti-entropy** — replicas periodically exchange Merkle trees to find and reconcile differences without comparing every key. The backstop for data nobody reads.

## Conflict Resolution

When two replicas accept conflicting writes, something must pick a winner. This is the decision BASE forces on you and the one most often made by accident.

| Strategy | How it works | Failure mode |
| --- | --- | --- |
| **Last-write-wins (LWW)** | Attach a timestamp; highest wins | **Silently discards data.** Clock skew between nodes means "last" is a guess; two concurrent writes mean one is simply lost |
| **Vector clocks** | Track causality; return siblings when writes are genuinely concurrent | Correct, but the application must merge siblings, and clock metadata grows |
| **CRDTs** | Types whose merge is commutative, associative, and idempotent, so convergence is automatic | Only works for operations expressible as a CRDT (counters, sets, registers, sequences); semantics can be surprising |
| **Application merge** | Domain logic decides — union the shopping carts, keep the higher balance | Most correct, most work; every write path needs it |

LWW is the default in most systems because it is the only one requiring no application involvement. It is also, for anything resembling a business record, usually the wrong choice — it converts a conflict into data loss with no log entry. The Dynamo paper's shopping-cart example exists precisely to illustrate the alternative: merging two divergent carts by union means a re-added item might reappear, which is a far better outcome than losing someone's order.

## What the Application Must Now Do

Adopting BASE adds obligations that ACID used to discharge for you:

- **Idempotency.** Retries are unavoidable and delivery is at-least-once, so every operation needs a dedup key or must be naturally idempotent. `SET balance = 100` is safe to repeat; `balance = balance - 10` is not.
- **Compensation instead of rollback.** There is no atomic multi-key transaction, so a multi-step business operation becomes a **saga**: a chain of local writes, each with a compensating action that undoes it. Intermediate states are visible by construction.
- **Designing for stale reads.** Every screen must have an answer to "what if this data is thirty seconds old?" — usually optimistic UI, a freshness indicator, or a conditional write that fails on a version mismatch.
- **Reconciliation.** A periodic job that detects and repairs divergence, because read repair only fixes what is read. In financial contexts this is literally an audit.
- **Monitoring replication lag as a correctness metric**, not a performance one. Lag is the window in which your invariants are violated.

## When BASE Is Right — and When It Is a Liability

**Good fit:** high write volume with independent keys, data whose value decays quickly, operations that are naturally commutative, and anything where a stale answer beats no answer.

- Session and cart state, user profiles and preferences
- Activity feeds, notifications, presence, social graphs
- Metrics, counters, logs, telemetry, clickstream
- Caches, search indexes, recommendation and personalization stores

**Bad fit:** anything with a global invariant or a uniqueness requirement, where the cost of a wrong answer exceeds the cost of an error.

- Ledgers, payments, double-entry accounting, anything audited
- Inventory with limited stock — overselling is the canonical BASE failure
- Uniqueness constraints: usernames, email addresses, seat and ticket allocation
- Authorization decisions, quota and rate limits, distributed locks and leader election

The failure is rarely dramatic. It looks like a slow drip of duplicate records, small unexplained balance discrepancies, and a reconciliation job that nobody can turn off — which is why the choice needs making deliberately rather than inheriting a default.

## ACID vs. BASE

| | **ACID** | **BASE** |
| --- | --- | --- |
| Consistency | Strong, enforced at commit | Eventual, converges in the background |
| Availability under partition | Sacrificed — refuse rather than diverge | Preserved — answer with whatever is local |
| Scaling model | Vertical, or horizontal with coordination cost | Horizontal, near-linear |
| Where conflicts are handled | Prevented by the database (locks, MVCC) | Resolved by the application, after the fact |
| Failure mode | Errors, timeouts, deadlocks — loud | Stale reads, lost updates, divergence — silent |
| Schema posture | Declared constraints do the enforcing | Constraints live in application code |
| Operational burden | Tuning contention and lock waits | Reconciliation, dedup, merge logic |

The last row of that table is the honest summary: neither philosophy removes work, they relocate it.

## The Dichotomy Has Softened

ACID-or-BASE was a real architectural fork around 2010. It is much less of one now, and treating it as binary dates a design discussion.

- **Distributed SQL** — Spanner, CockroachDB, YugabyteDB — provides genuine distributed ACID by paying in latency rather than by abandoning the guarantee.
- **Dynamo-lineage stores grew transactions.** DynamoDB has `TransactWriteItems`, Cassandra has lightweight transactions via Paxos, MongoDB has multi-document transactions. The AP default remains; strong consistency is now an opt-in per operation.
- **Consistency became a dial with labels.** Azure Cosmos DB exposes five named levels from strong to eventual, with documented latency and availability implications for each — the clearest admission that this was never two categories.
- **Analytics caught up too.** Lakehouse table formats brought atomic commits and snapshot isolation to object storage, so the data platform layer is no longer implicitly BASE either.

The modern framing is per-operation: pick the weakest guarantee that keeps the invariant you care about, and pay for a stronger one only where it is load-bearing.

## Common Pitfalls

- **Accepting the default conflict resolution.** If nobody chose, it is last-write-wins, and it is discarding writes without telling you.
- **Treating "eventual" as "in a few milliseconds".** It is a liveness property with no bound. Under load, node failure, or hinted-handoff backlog, the window stretches to minutes or hours.
- **Enforcing uniqueness in an eventually consistent store.** A read-then-write check has no isolation; two concurrent registrations both succeed. Uniqueness needs a linearizable store or an explicit lightweight transaction.
- **Assuming the whole system must pick one.** Put the ledger in Postgres and the feed in Cassandra. The boundary is the design.
- **Skipping the reconciliation job** because the happy path works in staging, where there are no partitions.
- **Calling it BASE when you mean "we did not think about consistency".** BASE is a deliberate trade with compensating machinery; the absence of that machinery is just a bug surface.

## Related Concepts

- [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the strict alternative BASE is defined in opposition to, and still the right default for anything with an invariant
- [[concepts/cap_theorem|CAP Theorem]] — the constraint that makes the BASE trade-off necessary; BASE is the AP branch made into a design philosophy
- [[concepts/isolation_levels|Transaction Isolation Levels]] — the same weakening of guarantees for throughput, applied within a single node
- [[concepts/data_architecture|Data Architecture]] — where the per-workload ACID/BASE boundary is drawn
- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — the write-optimized storage engine underneath most BASE stores
- [[concepts/api_integration_protocols|API and Integration Protocols]] — event-driven integration is BASE at the system boundary, with the same idempotency and ordering obligations
- [[concepts/data_quality|Data Quality]] — divergence and staleness surface downstream as consistency and timeliness failures, which is what reconciliation jobs measure

## References

- DeCandia et al., ["Dynamo: Amazon's Highly Available Key-Value Store"](https://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf), SOSP 2007 — the paper that made BASE mainstream.
- Dan Pritchett, ["BASE: An Acid Alternative"](https://queue.acm.org/detail.cfm?id=1394128), ACM Queue, 2008.
- Werner Vogels, ["Eventually Consistent"](https://queue.acm.org/detail.cfm?id=1466448), ACM Queue, 2008 — the session-guarantee taxonomy.
- Shapiro et al., ["Conflict-Free Replicated Data Types"](https://inria.hal.science/inria-00609399/document), 2011.
- Bailis and Ghodsi, ["Eventual Consistency Today: Limitations, Extensions, and Beyond"](https://queue.acm.org/detail.cfm?id=2462076), ACM Queue, 2013.
- Martin Kleppmann, *Designing Data-Intensive Applications*, Chapter 5 ("Replication").
- [Azure Cosmos DB: Consistency levels](https://learn.microsoft.com/en-us/azure/cosmos-db/consistency-levels)
