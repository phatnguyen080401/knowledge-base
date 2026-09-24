---
title: Transaction Isolation Levels
tags: [data-architecture, databases, transactions]
created: 2026-09-24 10:57:07
updated: 2026-09-24 11:24:31
---

# Transaction Isolation Levels

Isolation levels define what one transaction may observe of another transaction's in-flight work. They are the tunable part of the I in [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]], trading correctness guarantees against concurrency: the standard levels — Read Uncommitted, Read Committed, Repeatable Read, and Serializable — are specified by which anomalies each one permits rather than by how an engine implements them.

That specification-by-anomaly is why the same level name behaves differently across databases, and why the default level in most engines is weaker than application code assumes.

## Why It Matters

- **Your code already assumes a level, whether or not you chose one.** Every read-modify-write, every "check then insert", every balance update assumes some degree of isolation. If the assumption is wrong, the bug appears only under concurrency, corrupts data silently, and cannot be reproduced on demand.
- **The defaults are weaker than the names suggest.** PostgreSQL's default permits lost updates. Oracle's `SERIALIZABLE` is not serializable. MySQL's `REPEATABLE READ` prevents phantoms for reads but not for its own write path. None of this is visible from the level name.
- **It is the cheapest correctness lever you have.** Raising a single transaction's level is a one-line change; discovering you needed it after a year of silent divergence is a data-forensics project.

## The Anomalies

Levels are *defined* by which of these they forbid, so the anomalies come first. In each diagram, time runs downward and the two columns are concurrent transactions.

### Dirty write

One transaction overwrites a value another has written but not committed.

```text
T1                               T2
BEGIN                            BEGIN
UPDATE listing SET buyer = 'A'
                                 UPDATE listing SET buyer = 'B'
                                 UPDATE invoice  SET buyer = 'B'
UPDATE invoice  SET buyer = 'A'
COMMIT                           COMMIT
-- listing.buyer = 'B', invoice.buyer = 'A'
```

The sale is recorded as going to two different people. **Every isolation level forbids this**, universally implemented by holding a row-level write lock until commit. It is the one anomaly you never have to think about.

### Dirty read

A transaction reads a value another transaction has written but not committed — and that writer may still roll back.

```text
T1                               T2
BEGIN                            BEGIN
UPDATE account SET bal = 900
                                 SELECT bal FROM account   -- reads 900
                                 -- acts on money that never existed
ROLLBACK
```

Beyond reading values that are rolled back, a dirty read can see a transaction's *partial* work — the debit without the matching credit. Forbidden by Read Committed and above; permitted only at Read Uncommitted.

### Non-repeatable read (read skew)

A transaction reads the same row twice and gets different values, because another transaction committed in between.

```text
T1 (report)                      T2 (transfer £100 from A to B)
BEGIN
SELECT bal FROM acct WHERE id=A  -- 500
                                 BEGIN
                                 UPDATE acct SET bal=400 WHERE id=A
                                 UPDATE acct SET bal=600 WHERE id=B
                                 COMMIT
SELECT bal FROM acct WHERE id=B  -- 600
-- total reads as 1100; £100 appeared from nowhere
```

This is the anomaly that ruins any multi-statement read: backups, reports, analytical queries, and consistency checks all need a stable view. Forbidden by Repeatable Read / snapshot isolation and above.

### Phantom read

A transaction re-runs a query with a predicate and finds **rows that did not exist before** — the anomaly is about a *set* of rows, not a single row's value.

```text
T1                               T2
BEGIN
SELECT count(*) FROM booking
  WHERE room=1 AND day='Mon'     -- 0
                                 BEGIN
                                 INSERT INTO booking VALUES (1,'Mon',...)
                                 COMMIT
SELECT count(*) FROM booking
  WHERE room=1 AND day='Mon'     -- 1, a phantom
```

Row-level locks cannot prevent phantoms, because there is no row to lock — preventing them requires **predicate locks** or their practical approximation, **range/gap locks**.

### Lost update

Two transactions both read-modify-write the same row; one update is silently overwritten.

```text
T1                               T2
BEGIN                            BEGIN
SELECT counter  -- 42            SELECT counter  -- 42
-- app computes 43               -- app computes 43
UPDATE SET counter = 43
COMMIT                           UPDATE SET counter = 43
                                 COMMIT
-- two increments, counter = 43
```

This is by far the most common isolation bug in production, because the read-modify-write cycle happens in application code where the database cannot see the intent. Counters, inventory decrements, JSON document edits, and "append to a list" operations are all vulnerable.

### Write skew

Two transactions read an overlapping set of rows, each writes a *different* row, and together they break an invariant neither violated alone. It is the generalization of lost update where the write target differs from the read target.

```text
T1 (Alice going off-call)        T2 (Bob going off-call)
BEGIN                            BEGIN
SELECT count(*) FROM doctor      SELECT count(*) FROM doctor
  WHERE on_call = true  -- 2       WHERE on_call = true  -- 2
-- >= 2, safe to leave           -- >= 2, safe to leave
UPDATE doctor SET on_call=false  UPDATE doctor SET on_call=false
  WHERE name='Alice'               WHERE name='Bob'
COMMIT                           COMMIT
-- invariant "at least one doctor on call" is now violated
```

**Snapshot isolation does not prevent write skew**, and this is its defining limitation. The same shape appears in meeting-room booking, claiming a username, enforcing a spending limit across several rows, and any "check an aggregate, then insert" pattern — where it is sometimes called a *phantom-driven* write skew.

## The Standard Levels

| Level | Dirty write | Dirty read | Non-repeatable read | Phantom | Lost update | Write skew |
| --- | --- | --- | --- | --- | --- | --- |
| **Read Uncommitted** | Prevented | **Possible** | **Possible** | **Possible** | **Possible** | **Possible** |
| **Read Committed** | Prevented | Prevented | **Possible** | **Possible** | **Possible** | **Possible** |
| **Repeatable Read** (ANSI) | Prevented | Prevented | Prevented | **Possible** | Engine-dependent | **Possible** |
| **Snapshot Isolation** | Prevented | Prevented | Prevented | Prevented for reads | Usually prevented | **Possible** |
| **Serializable** | Prevented | Prevented | Prevented | Prevented | Prevented | Prevented |

The first four columns are the ANSI SQL-92 definition; the last two are the anomalies the standard omitted, which is precisely why the standard is not enough to reason with.

### Read Uncommitted

No read locks and no snapshot: you see other transactions' uncommitted work. It buys essentially nothing on an MVCC engine, since snapshots are already cheap — PostgreSQL accepts the syntax and silently gives you Read Committed instead. Defensible only for approximate analytical scans where a dirty row is noise, and even then rarely worth the reasoning cost.

### Read Committed

The workhorse default. Two guarantees: you only read committed data, and you only overwrite committed data. Crucially, **the snapshot is taken per statement, not per transaction** — so two `SELECT`s in the same transaction can see different states of the world.

On an MVCC engine each statement reads the newest committed version as of its own start, so readers never block. On a lock-based engine it means acquiring a shared lock for the duration of the read and releasing it immediately.

It prevents dirty reads and nothing else. Lost updates and write skew are wide open.

### Repeatable Read and Snapshot Isolation

The transaction takes **one snapshot at its start** and reads from it throughout, so every read is stable and repeatable. Implemented with MVCC: each row keeps a chain of versions tagged with the transaction ID that created it, and a reader ignores versions newer than its snapshot or belonging to uncommitted transactions. Cleaning up the versions no snapshot can still see is what PostgreSQL's `VACUUM` and Oracle's undo segments exist to do.

Writes are resolved by **first-committer-wins**: if two transactions update the same row, the second to commit is aborted with a serialization failure. That is what kills lost updates at this level in PostgreSQL.

ANSI Repeatable Read and snapshot isolation are not the same thing — the standard permits phantoms, while snapshot isolation excludes them from reads simply because the snapshot is fixed. Nearly every engine that advertises Repeatable Read is actually providing snapshot isolation.

What remains possible is write skew, and that is not a corner case: it is the failure mode behind most "our constraint was violated and we don't know how" incidents.

### Serializable

The result must equal *some* serial execution of the concurrent transactions. This is the only level that requires no reasoning about anomalies — if your transaction is correct when run alone, it is correct under concurrency. Three implementations exist:

| Implementation | Mechanism | Cost profile |
| --- | --- | --- |
| **Actual serial execution** | One transaction at a time, single-threaded, on an in-memory dataset | Zero concurrency overhead; requires short, stored-procedure-style transactions and a dataset that fits in RAM (VoltDB, Redis) |
| **Two-phase locking (2PL)** | Shared/exclusive locks plus predicate or index-range locks, all held until commit | Readers and writers block each other; deadlocks need detection and a victim abort; latency is unpredictable under contention |
| **Serializable Snapshot Isolation (SSI)** | Snapshot isolation plus tracking of read/write dependencies, aborting transactions that would form a cycle | Optimistic: no blocking, but aborts rise with contention; the application **must** retry |

SSI is the modern answer and what PostgreSQL uses. Its practical consequence is easy to miss: under SSI, **transactions fail at commit time as a matter of routine**. Code without a retry loop is not serializable, no matter what the level is set to.

## Why the ANSI Standard Is Not Enough

Berenson et al.'s 1995 paper *A Critique of ANSI SQL Isolation Levels* established three problems that still shape every engine's documentation:

1. **The phenomena are ambiguous.** The standard's English descriptions admit a narrow reading (a specific interleaving) and a broad one (any execution with that shape). Under the broad reading the levels mean something quite different, and vendors chose inconsistently.
2. **Snapshot isolation does not fit anywhere.** It prevents more than ANSI Repeatable Read (no phantoms on reads) and less than Serializable (write skew survives). The standard has no slot for the level that most databases actually implement.
3. **Lost update and write skew are missing entirely.** The two anomalies that cause the most production damage are not among the standard's phenomena, so a level can be standards-compliant and still permit them.

The practical conclusion: **read your engine's documentation, not the standard.** The level name tells you almost nothing portable.

## What Each Engine Actually Does

| Engine | Default | `REPEATABLE READ` is really | `SERIALIZABLE` is really | Notes |
| --- | --- | --- | --- | --- |
| **PostgreSQL** | Read Committed | Snapshot isolation | True serializability via SSI | `READ UNCOMMITTED` is silently upgraded to Read Committed; serialization failures (`40001`) must be retried |
| **MySQL / InnoDB** | Repeatable Read | Snapshot isolation + **gap locks**, which block most phantoms | 2PL — every plain `SELECT` becomes a locking read | Gap locking is a frequent and surprising source of deadlocks |
| **Oracle** | Read Committed | Not supported — the syntax raises an error | **Snapshot isolation**, so write skew is still possible | Statement-level read consistency from undo segments |
| **SQL Server** | Read Committed (lock-based) | 2PL with shared locks held to commit | 2PL with range locks | Enabling `READ_COMMITTED_SNAPSHOT` switches the default to MVCC; `SNAPSHOT` is a separate, explicit level |
| **CockroachDB / Spanner** | Serializable | — | True serializability | Strict by default; the application retries on conflict |
| **SQLite** | Serializable | — | True serializability | One writer at a time; WAL mode lets readers proceed concurrently |

The single most important row to internalize: **Oracle's `SERIALIZABLE` is snapshot isolation.** Code written against Oracle and ported to PostgreSQL's true `SERIALIZABLE` will start seeing serialization failures; code ported the other way will start silently permitting write skew.

## Preventing Lost Updates Without Going Serializable

Most applications do not need full serializability — they need this one class of bug gone. Five options, roughly in order of preference:

1. **Make the operation atomic in SQL.** `UPDATE counter SET value = value + 1 WHERE id = 1` takes an exclusive lock and re-reads the current value inside the engine. No read-modify-write cycle exists, so nothing can be lost. Always prefer this when the update is expressible as one statement.
2. **Compare-and-set (optimistic locking).** Add a `version` column and make the update conditional:
   ```sql
   UPDATE doc SET body = ?, version = version + 1
   WHERE id = ? AND version = ?;
   ```
   If zero rows are affected, someone else won — re-read and retry. This is what every ORM's `@Version` annotation does, and it works across request boundaries where a transaction cannot be held open.
3. **Explicit pessimistic locking.** `SELECT ... FOR UPDATE` takes a write lock at read time, serializing the read-modify-write cycle for those rows. Correct and simple; the cost is contention and deadlock risk if transactions lock rows in differing orders.
4. **Rely on automatic detection.** PostgreSQL and Oracle detect lost updates at Repeatable Read and abort the loser. Free, but only if you are at that level *and* you retry.
5. **Raise the level to Serializable.** Correct for every anomaly, not just this one — at the cost of more aborts and a mandatory retry loop.

Write skew is harder: only options 3 and 5 address it, because the row you write is not the row you read. Materializing the conflict — locking a parent row representing the invariant, for example — is the standard workaround when raising the level is not an option.

## Choosing a Level

1. **Start at the engine default** and know exactly what it does and does not prevent.
2. **Raise the level per transaction, not globally.** `SET TRANSACTION ISOLATION LEVEL SERIALIZABLE` on the handful of transactions that carry an invariant is far cheaper than paying for it everywhere.
3. **Use Repeatable Read / snapshot isolation for anything that reads more than one row and expects a coherent picture:** reports, exports, backups, integrity checks, and any multi-statement read.
4. **Use Serializable when an invariant spans rows** — uniqueness checks, booking and allocation, limits and quotas, state machines. If you cannot state the invariant in a single row, you need it.
5. **Always pair Serializable and Repeatable Read with a retry loop** with bounded attempts and jittered backoff, retrying only on the serialization-failure error code.
6. **Keep transactions short.** Every level's cost — lock hold time, abort probability, version accumulation — scales with transaction duration. Never hold one open across a user interaction or an external API call.

## Common Pitfalls

- **Assuming the level name is portable.** It is not. Verify against the engine's own documentation before relying on a guarantee.
- **Setting `SERIALIZABLE` without retry handling.** You have converted silent corruption into unhandled runtime errors, which is better, but you have not achieved serializability.
- **Doing the read-modify-write in application code** when a single atomic `UPDATE` would do.
- **Assuming Read Committed makes a `SELECT` then `UPDATE` safe.** Nothing links the two statements; anything can commit in between.
- **Ignoring write skew because the code "checks first".** The check and the write are not atomic under snapshot isolation, and the check passing is exactly what makes both transactions proceed.
- **Long-running transactions at Repeatable Read.** The held snapshot pins old row versions, blocking vacuum and bloating tables for every other session.
- **Treating a serialization failure as an outage.** Under SSI it is the mechanism working as designed; the correct response is to retry, and to alarm only on the rate.
- **Forgetting that isolation stops at the database boundary.** Two application processes coordinating through an external cache or queue get no isolation at all.

## Related Concepts

- [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the parent guarantee; isolation levels are the dial on its I, and the concurrency-control mechanisms behind them are described there
- [[concepts/cap_theorem|CAP Theorem]] — the distributed analogue of the same correctness-versus-performance trade-off, where linearizability replaces serializability
- [[concepts/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]] — what happens when the trade is pushed all the way toward availability and isolation is abandoned entirely
- [[concepts/data_architecture|Data Architecture]] — the level a workload runs at is a design decision, not an operational detail
- [[concepts/b_plus_tree|B+ Tree]] — the index structure that range and gap locks are taken on, which is why MySQL's phantom prevention depends on the query's index plan
- [[concepts/data_quality|Data Quality]] — isolation bugs surface downstream as accuracy and consistency defects that no data test can attribute to their cause

## References

- Berenson, Bernstein, Gray, Melton, O'Neil, O'Neil, ["A Critique of ANSI SQL Isolation Levels"](https://arxiv.org/abs/cs/0701157), SIGMOD 1995.
- Adya, Liskov, O'Neil, *Generalized Isolation Level Definitions*, ICDE 2000 — implementation-independent definitions that fix the ANSI ambiguity.
- Ports and Grittner, ["Serializable Snapshot Isolation in PostgreSQL"](https://drkp.net/papers/ssi-vldb12.pdf), VLDB 2012.
- Fekete et al., *Making Snapshot Isolation Serializable*, ACM TODS 2005 — the theory behind SSI.
- Martin Kleppmann, *Designing Data-Intensive Applications*, Chapter 7 ("Transactions").
- [PostgreSQL: Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
- [MySQL: InnoDB Transaction Isolation Levels](https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html)
- Peter Bailis, ["When is “ACID” ACID? Rarely."](http://www.bailis.org/blog/when-is-acid-acid-rarely/) — a survey of what commercial engines default to.
