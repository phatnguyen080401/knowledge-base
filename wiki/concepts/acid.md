---
title: ACID (Atomicity, Consistency, Isolation, Durability)
tags: [data-architecture, databases, transactions]
created: 2026-09-24 10:57:07
updated: 2026-09-24 10:57:07
---

# ACID (Atomicity, Consistency, Isolation, Durability)

ACID is the set of four guarantees a database makes about a transaction — a group of reads and writes treated as a single unit. It is the contract that lets application code assume "either all of this happened or none of it did, and nobody saw the middle," and choosing how much of it to keep is one of the structural decisions of [[concepts/data_architecture|Data Architecture]].

## Why It Matters

- **It is a contract you code against, not a feature you enable.** Every retry, every "check then update", every balance transfer assumes some isolation level. Getting the assumption wrong produces corruption that no test catches and no monitoring alerts on.
- **It sets the throughput ceiling.** Durability costs an `fsync`; isolation costs locks or version chains. Most database tuning is negotiating how much of ACID you are willing to pay for.
- **"ACID or eventual?" is the pivotal system-design call.** It decides whether you can scale by adding nodes, and whether correctness lives in the database or in your application code.

## The Four Properties

| Property | Guarantee | What breaks without it | Provided by |
| --- | --- | --- | --- |
| **Atomicity** | All writes in the transaction commit, or none do | Partial writes after a crash or error; money debited but never credited | Undo log / rollback segments |
| **Consistency** | The database's declared constraints hold before and after | Orphaned foreign keys, duplicate "unique" values, negative balances | Constraint checking at commit |
| **Isolation** | Concurrent transactions do not observe each other's partial state | Lost updates, phantom rows, write skew | Locking (2PL), MVCC, or OCC |
| **Durability** | Once committed, the write survives a crash | Acknowledged writes silently vanish on power loss | Write-ahead log + `fsync` |

### Atomicity

Atomicity is *abortability*: if anything goes wrong midway — a constraint violation, a deadlock, a crash, a client disconnect — the transaction is rolled back as if it never ran.

The mechanism is an **undo log**. Before modifying a page, the engine records enough information to reverse the change. On `ROLLBACK`, or during crash recovery for a transaction that never committed, those records are replayed backwards.

**Savepoints** create nested rollback targets inside one transaction, which is how ORMs implement "try this sub-operation, and if it fails keep going". They are not separate transactions — an outer rollback still discards everything.

Atomicity says nothing about concurrency. A transaction can be perfectly atomic and still read garbage written by a neighbour; that is isolation's job.

### Consistency

Consistency is the odd one out, and the source of most confusion. The database only enforces **the constraints you declared**: primary keys, foreign keys, `UNIQUE`, `NOT NULL`, `CHECK`, and triggers. If a transaction would leave any of them violated, it is rejected.

Everything else — "an order must have at least one line item", "these two ledger columns must sum to zero" — is an *application* invariant. The database cannot know about it, so the application must express it as a declared constraint or enforce it under sufficient isolation.

> [!warning] ACID's C is not CAP's C
> In ACID, consistency means "declared constraints are not violated". In the [[concepts/cap_theorem|CAP Theorem]], consistency means *linearizability* — every read sees the most recent write across all replicas. The two are unrelated, and conflating them is the most common error in system-design discussions.

Because it is mostly the application's responsibility, Joe Hellerstein has noted that the C was arguably added to make the acronym pronounceable. Treat it as "the database enforces the integrity rules you gave it" and move on.

### Isolation

Isolation defines what a transaction can observe while other transactions are running. The gold standard is **serializability**: the result must be identical to *some* serial order of the concurrent transactions. Full serializability is expensive, so every engine offers weaker levels — and those levels are defined by which anomalies they permit, covered in [[concepts/isolation_levels|Transaction Isolation Levels]].

The practical consequence: **the default isolation level of your database is weaker than you think**. Postgres defaults to Read Committed, which permits lost updates and write skew. MySQL InnoDB defaults to Repeatable Read. Neither prevents two concurrent transactions from reading the same balance and both deducting from it.

### Durability

Durability means that once the database acknowledges a commit, the write survives a crash. The mechanism is the **write-ahead log**: the log record is flushed to stable storage *before* the commit is acknowledged, so recovery can replay it even if the data pages were never written.

Durability is a spectrum, not a boolean, and the dial is which storage the log reached:

| Setting | Survives | Cost |
| --- | --- | --- |
| Log buffered in memory | Process crash only | Fastest; a power loss loses committed writes |
| Log written to OS page cache | Process crash | Fast; a machine crash can lose writes |
| Log `fsync`ed to disk | Machine crash | One durable write per commit |
| Log `fsync`ed **and** acknowledged by a synchronous replica | Loss of the whole node | Adds a network round trip to every commit |

Asynchronous replicas are *not* durable in this sense. If the primary's disk dies before the replica catches up, acknowledged commits are gone — a failure mode that looks exactly like data corruption to the application.

## How Engines Actually Deliver It

### The write-ahead log

Every mainstream engine funnels durability and atomicity through one structure: an append-only log written before the data pages it describes.

```text
commit ──> WAL record appended ──> fsync ──> client acknowledged
                                               │
                     (later, asynchronously)   ▼
                                    dirty pages flushed to disk
```

Recovery follows the **ARIES** pattern in three passes: *analyse* the log from the last checkpoint to find which transactions were in flight, *redo* every logged change to restore the exact pre-crash state, then *undo* the transactions that never committed. Redo-then-undo is what makes atomicity and durability fall out of the same log.

**Checkpoints** bound recovery time by flushing dirty pages and recording how far back the log must be read. They are why a database restarts in seconds rather than replaying weeks of log.

The log interacts with the storage structure underneath it:

- A [[concepts/b_plus_tree|B+ Tree]] updates pages **in place**, so a torn page (partially written during a power loss) would corrupt the index. Postgres guards against this by writing full page images to the WAL after each checkpoint — a major source of write amplification.
- A [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] never overwrites anything, so it has no torn-page problem; its WAL exists purely to replay the in-memory memtable that had not yet been flushed.

### Concurrency control

Three families of mechanism implement isolation, and the choice shapes the engine's entire performance profile.

| Mechanism | How it prevents conflicts | Cost | Where you see it |
| --- | --- | --- | --- |
| **Two-phase locking (2PL)** | Acquire shared/exclusive locks, release none until commit | Readers block writers and vice versa; deadlocks must be detected and a victim aborted | SQL Server and DB2 by default; Postgres/MySQL for explicit `SELECT ... FOR UPDATE` |
| **MVCC** | Each write creates a new version; readers see a consistent snapshot as of their start | Version storage, and a vacuum/purge process to reclaim dead versions | PostgreSQL, Oracle, MySQL InnoDB, and effectively every modern engine |
| **Optimistic (OCC / SSI)** | Let transactions run, detect conflicts at commit, abort the loser | Wasted work and retries under contention; near-free when contention is low | Postgres `SERIALIZABLE` (Serializable Snapshot Isolation), FoundationDB, most distributed SQL engines |

MVCC's defining property is that **readers never block writers and writers never block readers** — the single biggest reason it displaced pure 2PL. The price is bookkeeping: Postgres must `VACUUM` dead tuples, Oracle must size undo segments, and a long-running read transaction pins old versions and bloats the table for everyone.

Optimistic control changes the failure mode rather than removing it. Under `SERIALIZABLE`, transactions do not block — they **fail at commit** with a serialization error, and the application is required to retry. Code that does not handle that error is not serializable, whatever the setting says.

### The commit path

The `fsync` on commit is the single most expensive operation in an OLTP system, so engines amortize it with **group commit**: batch the log records of many concurrent transactions and flush them together, turning N syncs into one. This is why throughput often *improves* with concurrency up to a point.

The knobs that trade durability for latency are worth knowing by name, because they are the most commonly (and most dangerously) tuned settings in any database:

- **PostgreSQL** — `synchronous_commit` (`on`, `local`, `remote_write`, `remote_apply`, `off`). Setting it `off` keeps atomicity and consistency but permits losing the last fraction of a second of committed transactions.
- **MySQL InnoDB** — `innodb_flush_log_at_trx_commit` (`1` = fsync per commit and fully ACID, `0`/`2` = faster and not).

Both defaults are safe. Both are routinely turned down for throughput, usually without the trade-off being written down anywhere.

## Isolation Levels in Practice

Isolation levels are defined by which **anomalies** they allow, not by how they are implemented — which is why the same level name behaves differently across engines.

| Anomaly | What happens |
| --- | --- |
| **Dirty read** | You read a value another transaction wrote but has not committed |
| **Dirty write** | You overwrite a value another transaction wrote but has not committed |
| **Non-repeatable read** | You read the same row twice in one transaction and get different values |
| **Phantom read** | You re-run the same query and new rows have appeared that match it |
| **Lost update** | Two transactions read-modify-write the same row; one update silently disappears |
| **Write skew** | Two transactions read an overlapping set, each writes a different row, and together they break an invariant neither violated alone |

| Level | Dirty read | Non-repeatable read | Phantom | Lost update | Write skew |
| --- | --- | --- | --- | --- | --- |
| Read Uncommitted | Possible | Possible | Possible | Possible | Possible |
| Read Committed | Prevented | Possible | Possible | Possible | Possible |
| Repeatable Read / Snapshot | Prevented | Prevented | Engine-dependent | Engine-dependent | Possible |
| Serializable | Prevented | Prevented | Prevented | Prevented | Prevented |

Real-world defaults, which rarely match the assumption in application code:

- **PostgreSQL** — Read Committed. Its "Repeatable Read" is actually snapshot isolation, and `SERIALIZABLE` uses SSI and aborts conflicting transactions.
- **MySQL InnoDB** — Repeatable Read, with gap locks that block most (but not all) phantoms.
- **Oracle** — Read Committed; its `SERIALIZABLE` is snapshot isolation and therefore still permits write skew.
- **SQL Server** — Read Committed using locks by default, or MVCC if Read Committed Snapshot Isolation is enabled.

## Where ACID Breaks Down

ACID is a **single-node** achievement. The moment a transaction spans machines, every guarantee needs a distributed protocol to hold it together.

- **Two-phase commit (2PC)** extends atomicity across nodes: a coordinator asks every participant to prepare, then tells them all to commit or abort. It works, but it is *blocking* — a participant that has voted "prepared" must hold its locks until the coordinator returns, so a coordinator crash can freeze rows indefinitely. This is why 2PC is avoided in high-throughput systems.
- **Distributed SQL engines** — Spanner, CockroachDB, YugabyteDB — do provide distributed ACID, by paying for it elsewhere: consensus (Raft/Paxos) on every write, and either atomic clocks and commit-wait (Spanner's TrueTime) or hybrid logical clocks. The guarantee is real; the latency floor is set by the speed of light between regions.
- **Sagas** abandon distributed atomicity deliberately. A business operation becomes a sequence of local transactions, each with a compensating transaction that undoes it. There is no isolation between steps, so intermediate states *are* visible and must be designed for.
- **Eventually consistent stores** drop the guarantees in exchange for availability and partition tolerance, an approach summarized as [[concepts/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]] and bounded by the [[concepts/cap_theorem|CAP Theorem]].

## ACID in Data Platforms

Analytical systems spent years without transactions: a failed Spark job left a half-written directory, and readers saw whatever files happened to exist. Table formats fixed this by putting a transaction log over object storage.

- **Delta Lake, Apache Iceberg, and Apache Hudi** each maintain a metadata log or manifest listing exactly which data files constitute the current table. A write stages new files, then atomically swaps a single pointer. Readers resolve the pointer once and see a consistent snapshot — **atomicity and snapshot isolation without locking anything**.
- Because old snapshots remain until expiry, the same mechanism gives **time travel** and cheap rollback, which is the analytics equivalent of an undo log.
- Concurrent writers are handled optimistically: conflicting commits are detected against the log and retried, mirroring OCC.
- **Warehouses** vary. BigQuery gives atomic single statements and multi-statement transactions over its own storage; Snowflake gives full ACID on its micro-partitions.

This matters directly for pipelines: it is why a [[concepts/dbt|dbt (Data Build Tool)]] model can rebuild a table without downstream consumers ever seeing it empty or partial. The `table` materialization builds into a temporary relation and swaps it in atomically, which only works because the platform underneath provides atomic metadata operations. Partial writes are a [[concepts/data_quality|Data Quality]] failure that no downstream test can distinguish from genuinely bad data, so the guarantee is a prerequisite for trusting any quality check at all.

## Common Pitfalls

- **Assuming the default level prevents lost updates.** Read Committed does not. Use `SELECT ... FOR UPDATE`, an atomic `UPDATE ... SET x = x - 1`, or a compare-and-set on a version column.
- **Confusing ACID's C with CAP's C.** They have nothing to do with each other.
- **Using `SERIALIZABLE` without retry logic.** Under SSI, serialization failures are normal operation, not exceptional. No retry loop means no serializability.
- **Long-running transactions.** An idle-in-transaction session pins MVCC versions, blocks vacuum, bloats tables, and holds locks. Keep transactions short, and never hold one open across a user interaction or an external API call.
- **Treating asynchronous replicas as durable.** They acknowledge nothing about the commit.
- **Wrapping the wrong scope.** A transaction spanning an HTTP call to a third party cannot be rolled back — the external side effect already happened. Move side effects outside the transaction or use an outbox.

## Related Concepts

- [[concepts/data_architecture|Data Architecture]] — the parent discipline; how much of ACID to keep is one of its defining structural trade-offs
- [[concepts/isolation_levels|Transaction Isolation Levels]] — the I expanded: which anomalies each level actually permits
- [[concepts/cap_theorem|CAP Theorem]] — why ACID does not survive unchanged once data is distributed across nodes
- [[concepts/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]] — the deliberate alternative when availability outranks strict correctness
- [[concepts/b_plus_tree|B+ Tree]] — the in-place storage structure whose torn-page risk shapes how the WAL is written
- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — the append-only alternative, whose WAL exists only to replay the memtable
- [[concepts/data_quality|Data Quality]] — transactions enforce integrity at write time; quality rules audit it afterwards
- [[concepts/dbt|dbt (Data Build Tool)]] — depends on atomic table swaps so that rebuilt models are never observed half-written

## References
