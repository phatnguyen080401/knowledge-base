---
title: Multiversion Concurrency Control (MVCC)
tags: [databases, transactions, concurrency-control, stub]
created: 2026-10-26 23:17:48
updated: 2026-10-26 23:17:48
---

# Multiversion Concurrency Control (MVCC)

Multiversion concurrency control is a concurrency-control method in which a write creates a new
version of a row instead of overwriting it. Each transaction reads from a consistent snapshot of
the versions visible to it, so readers never block writers and writers never block readers. It is
how most engines implement snapshot-based
[[concepts/databases/isolation_levels|Transaction Isolation Levels]].

## Related Concepts

- [[concepts/databases/isolation_levels|Transaction Isolation Levels]] — snapshot isolation and read committed are commonly built on MVCC, and its gaps explain write skew
- [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — MVCC is one of the mechanisms behind the I
- [[concepts/software_architecture/concurrency_and_parallelism|Concurrency and Parallelism]] — the lock-based alternative in application memory that MVCC avoids for reads
- [[concepts/databases/write_ahead_log|Write-Ahead Log (WAL)]] — records each new version for crash recovery
