---
title: Distributed Consensus
tags: [databases, distributed-systems, fault-tolerance, replication, stub]
created: 2026-10-26 23:17:48
updated: 2026-10-26 23:17:48
---

# Distributed Consensus

Distributed consensus is the problem of getting a group of nodes to agree on a single value, or an
ordered log of values, even when some nodes crash or messages are delayed. Protocols such as Paxos
and Raft solve it with majority quorums, and they underpin leader election and strongly consistent
replication on the consistency side of the [[concepts/databases/cap_theorem|CAP Theorem]].

## Related Concepts

- [[concepts/databases/cap_theorem|CAP Theorem]] — consensus is how a CP system stays consistent, and why it gives up availability when it cannot reach a majority
- [[concepts/databases/base_consistency|BASE (Basically Available, Soft State, Eventual Consistency)]] — the alternative that avoids consensus on every write and settles for eventual agreement
- [[concepts/databases/write_ahead_log|Write-Ahead Log (WAL)]] — a replicated log is the usual thing consensus protocols agree on
- [[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]] — KRaft, its built-in Raft quorum of controller nodes, coordinates cluster metadata and leader election
- [[concepts/software_architecture/idempotency|Idempotency]] — the cheaper tool for unreliable networks when an operation only needs to be safe to repeat, not globally ordered
