---
title: Apache Kafka
tags: [data-engineering, distributed-systems, kafka, overview]
created: 2026-10-22 10:50:05
updated: 2026-10-31 10:43:45
---

# Apache Kafka

Kafka is a distributed, partitioned, replicated **commit log** that systems write events to and read events from. It is not a message queue that deletes on delivery and not a database you query — it is durable, ordered, replayable storage for streams of events, sitting at the ingestion edge of a [[concepts/data_architecture/data_architecture|Data Architecture]] and decoupling the systems that produce data from the ones that consume it.

## Why It Matters

- **It breaks the N×M integration problem.** Without a log, every producer integrates with every consumer. With one, producers write once and any number of consumers read independently, each at its own pace.
- **The log is replayable.** A consumer is a cursor over retained data, not a recipient of a delivered message. Reprocessing a year of events through fixed logic means resetting an offset, not asking upstream systems to resend.
- **It absorbs mismatched speeds.** A burst that would overwhelm a downstream database becomes disk on the brokers; the consumer falls behind and catches up instead of failing.
- **Durability and ordering are configurable, not assumed.** Replication factor, `acks`, and `min.insync.replicas` make the durability/latency trade-off an explicit setting — which is why Kafka is a worked example in the [[concepts/databases/cap_theorem|CAP Theorem]] note.
- **It is the substrate for stream processing.** [[concepts/data_engineering/spark/apache_spark|Apache Spark]], [[concepts/data_engineering/flink/apache_flink|Apache Flink]], and Kafka Streams all assume a replayable, partitioned source; checkpoint-and-replay recovery is only possible because the log keeps the data.

## The Data Model

| Term          | What it is                                                                                     |
| ------------- | ---------------------------------------------------------------------------------------------- |
| **Record**    | An immutable event: optional key, value (opaque bytes), headers, timestamp                     |
| **Topic**     | A named, logical stream of records — the unit producers and consumers address                  |
| **Partition** | An ordered, append-only log file; a topic is split into one or more, and this is the unit of parallelism, ordering, and replication |
| **Offset**    | A monotonically increasing position within one partition; the consumer's only bookmark         |

Three consequences follow directly and account for most Kafka design decisions:

1. **Ordering is per partition, never per topic.** If two events must be processed in order, they must land in the same partition — which means giving them the same key.
2. **The key chooses the partition.** The default partitioner hashes the key; a null key spreads records round-robin. Keying by `customer_id` guarantees per-customer ordering and per-customer affinity to one consumer.
3. **Records are immutable and retained by policy, not by consumption.** Reading does not delete. Data leaves when retention expires or compaction supersedes it.

## Brokers, Replication, and Durability

A cluster is a set of **brokers**. Each partition has one **leader** replica that serves all reads and writes, plus follower replicas that fetch from it. The set of replicas currently caught up is the **in-sync replica set (ISR)**, and only ISR members are eligible to take over on leader failure.

The producer's `acks` setting decides what "written" means:

| `acks` | Leader waits for                      | Lost on leader failure                        |
| ------ | ------------------------------------- | --------------------------------------------- |
| `0`    | Nothing — fire and forget             | Anything in flight                            |
| `1`    | Its own local write                   | Records the followers had not yet fetched     |
| `all`  | All in-sync replicas                  | Nothing, provided `min.insync.replicas` > 1   |

`acks=all` alone is not enough: with `min.insync.replicas=1`, a topic that has shrunk to a single in-sync replica still accepts writes and still loses them. The durable configuration is replication factor 3, `min.insync.replicas=2`, `acks=all` — writes fail loudly once two replicas are unavailable rather than succeeding silently into a single copy.

Cluster metadata and leader election were historically coordinated by ZooKeeper. **KRaft** — a built-in Raft quorum of controller nodes — replaced it, and Kafka 4.0 removed the ZooKeeper mode entirely, leaving one process type and no external dependency.

## Producers

- **Batching is the throughput lever.** The producer accumulates records per partition and sends them together, governed by `batch.size` and `linger.ms`. Adding a few milliseconds of `linger.ms` typically multiplies throughput, because compression also applies per batch.
- **Idempotence removes duplicates from retries.** With `enable.idempotence=true` the broker deduplicates retried sends using a producer ID and sequence number, so a network-level retry no longer writes the record twice. This is the default in modern clients.
- **Transactions span partitions.** A transactional producer commits writes across several partitions atomically, which is what makes consume-process-produce loops exactly-once — and what `isolation.level=read_committed` consumers rely on to skip aborted records.

## Consumers and Consumer Groups

Consumers that share a `group.id` form a **consumer group**, and the group's members divide the partitions between them. The rules are rigid and worth stating plainly:

- A partition is assigned to **at most one consumer in a group**. Adding consumers beyond the partition count leaves them idle — partition count is the ceiling on a group's parallelism.
- Independent groups each get the full stream. Fan-out is achieved by adding groups, not by copying topics.
- When members join, leave, or time out, the group **rebalances** and reassigns partitions. Frequent rebalances — usually caused by processing that outruns `max.poll.interval.ms` — can stall a group indefinitely; cooperative incremental rebalancing reduces the stop-the-world effect but does not remove the cause.
- Progress is a **committed offset** per partition, stored in Kafka itself. Where you commit relative to processing decides the delivery semantics.

### Delivery semantics

| Semantics         | How it arises                                                        | Failure mode                          |
| ----------------- | -------------------------------------------------------------------- | ------------------------------------- |
| **At most once**  | Commit the offset before processing                                  | Crash loses the in-flight records     |
| **At least once** | Process, then commit — the practical default                         | Crash reprocesses; consumers must be idempotent |
| **Exactly once**  | Idempotent producer + transactions + `read_committed`                | Only within Kafka; an external sink needs its own idempotency |

> [!warning] "Exactly-once" ends at the Kafka boundary
> Kafka's transactions cover reading from Kafka and writing back to Kafka. The moment a consumer writes to a database, an API, or object storage, exactness becomes that sink's problem — solved with idempotent upserts on a business key, not with a Kafka setting.

## Retention and Compaction

Two independent cleanup policies, and choosing the wrong one is a common mistake:

- **Delete (time or size based).** Records older than `retention.ms`, or beyond `retention.bytes`, are discarded. This is the policy for event streams — clickstream, telemetry, orders — where the record of *what happened* matters.
- **Compact.** Kafka retains at least the latest value for every key and garbage-collects superseded ones. The topic becomes a durable, replayable snapshot of current state — the right policy for change data capture, configuration, and lookup tables. A record with a null value is a **tombstone** that marks the key deleted.

Compaction guarantees the latest value survives; it does not guarantee that intermediate values are gone promptly, and it never compacts the active segment.

## The Ecosystem

| Component           | Role                                                                             |
| ------------------- | --------------------------------------------------------------------------------- |
| **Kafka Connect**   | Declarative source and sink connectors — databases, object storage, warehouses — run as a cluster, with change data capture via Debezium as the dominant source pattern |
| **Kafka Streams**   | A JVM library (not a cluster) for stateful transformation, joins, and windowing with state held in local RocksDB and backed by changelog topics |
| **Schema Registry** | Holds Avro/Protobuf/JSON schemas and enforces compatibility on write, so producers cannot publish a breaking change — see [[concepts/data_governance/metadata_management|Metadata Management]] |
| **MirrorMaker 2**   | Replicates topics across clusters for disaster recovery or regional aggregation   |

Schema Registry, and the stricter forms of its compatibility checking, are what make a topic a contract rather than a byte stream; its compatibility modes are the streaming equivalent of the promises described in [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]].

## What Kafka Is Not

- **Not a database.** There is no query, no secondary index, no server-side filtering. A consumer reads the partition and discards what it does not want.
- **Not a task queue.** There is no per-message acknowledgement, no selective redelivery, no per-message visibility timeout, and no built-in dead-letter queue. One poisoned record blocks its partition until the application decides to skip it. For per-message work distribution, a broker like RabbitMQ or SQS fits better.
- **Not globally ordered.** Any claim about ordering is a claim about one partition.
- **Not low-overhead at small scale.** A three-broker cluster, a registry, and a Connect cluster are real operational weight; a single nightly extract does not need it.

## Operating Concerns

- **Partition count is close to irreversible.** It can be increased but never decreased, and increasing it rehashes keys to different partitions, breaking per-key ordering across the change. Size for the throughput you expect, not the throughput you have.
- **Key skew creates hot partitions.** One oversized key pins an entire partition's traffic to one consumer, and no amount of extra consumers helps — the same skew problem that afflicts [[concepts/data_engineering/spark/apache_spark|Spark]] shuffles.
- **Consumer lag is *the* health metric.** Not CPU, not broker disk — lag per group per partition, and whether its derivative is positive.
- **Retention is a liability as well as an asset.** Personal data sitting in a topic for 90 days is in scope for [[concepts/data_governance/data_security|Data Security]] and for deletion requests, and compaction tombstones are the only key-level erasure mechanism available.

## Related Concepts

- [[concepts/data_engineering/spark/apache_spark|Apache Spark]] — the most common processing engine reading from Kafka; its exactly-once story depends on Kafka offsets being replayable
- [[concepts/software_architecture/exactly_once_delivery_and_processing|Exactly-Once Delivery and Processing]] — the vendor-neutral theory behind the delivery-semantics table: why exactly-once delivery is impossible and exactly-once processing is a boundary
- [[concepts/data_architecture/data_architecture|Data Architecture]] — where the batch-versus-streaming decision that justifies Kafka gets made, and where its costs are argued
- [[concepts/databases/cap_theorem|CAP Theorem]] — Kafka's ISR and `acks` settings are a per-write consistency/availability dial, not a fixed position
- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — situates the log alongside the other messaging styles, including AMQP brokers that solve the opposite problem
- [[concepts/data_governance/metadata_management|Metadata Management]] — schema registries are the enforcement point for streaming contracts and the source of streaming lineage
- [[concepts/data_structures/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — Kafka Streams keeps its local state in RocksDB, so stateful stream processing inherits the LSM performance profile
- [[concepts/data_engineering/stateful_vs_stateless_stream_processing|Stateful vs. Stateless Stream Processing]] — what consumers built on Kafka must do once they remember anything: partitioned state, changelogs, consistent snapshots, and sink idempotency
