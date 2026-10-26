---
title: Write-Ahead Log (WAL)
tags: [databases, transactions, stub]
created: 2026-10-26 23:17:48
updated: 2026-10-26 23:17:48
---

# Write-Ahead Log (WAL)

A write-ahead log is an append-only file to which a database writes each change before it
modifies the data pages, so committed transactions can be replayed after a crash. It is the
mechanism behind the durability and atomicity guarantees of
[[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]], and shipping it to
other nodes is a common basis for replication.

## Related Concepts

- [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the guarantees the WAL exists to provide
- [[concepts/data_structures/b_plus_tree|B+ Tree]] — the in-place structure whose page writes the WAL protects
- [[concepts/data_structures/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — uses a WAL only to rebuild the in-memory memtable after a crash
- [[concepts/databases/multiversion_concurrency_control|Multiversion Concurrency Control (MVCC)]] — the version changes MVCC creates are recorded in the WAL like any other write
- [[concepts/databases/distributed_consensus|Distributed Consensus]] — consensus protocols replicate a log with the same append-then-apply discipline
