---
title: Real-Time Analytics Database
tags: [databases, indexing, query-optimization, write-optimization, partitioning, clickhouse, druid, pinot, needs-review]
sources: ["https://clickhouse.com/docs/academic_overview", "https://druid.apache.org/docs/latest/design/", "https://druid.apache.org/docs/latest/design/architecture/", "https://docs.pinot.apache.org/basics/architecture"]
created: 2026-10-29 18:38:49
updated: 2026-10-30 11:25:32
---

# Real-Time Analytics Database

A real-time analytics database is a column-oriented OLAP database built to ingest streaming events
and make them queryable within seconds, while answering analytical queries (filters, aggregations,
joins) in milliseconds for thousands of concurrent users over years of retained history. It
occupies the serving layer of a [[concepts/data_architecture/data_architecture|Data Architecture]]
where a batch warehouse is too slow and a stream processor keeps too little history; ClickHouse,
Apache Druid, and Apache Pinot are the common open-source examples.

## Why It Matters

- **Analytics has moved into products.** Usage dashboards, in-app metrics, and personalisation put
  analytical queries behind a web request, where every user generates queries and nobody waits ten
  seconds.
- **General-purpose engines hit a wall.** A transactional database can serve fresh data but not
  aggregate billions of rows quickly; a cloud warehouse can aggregate but is tuned for batch loads
  and a handful of concurrent analysts. Adapting either usually means sharding, caching, and
  extensive tuning.
- **The requirements fight each other.** Fast writes favour append-only structures, fast reads favour
  sorted, indexed, compressed columns; a real-time analytics database is defined by how it reconciles
  the two.

## The Five Requirements

The requirements are commonly framed as five facets that a real-time analytics system must meet at
once, a framing popularised by the vendor Tinybird:

| Facet | Target | What makes it hard |
| --- | --- | --- |
| Data freshness | Events queryable within seconds of arrival | Writing continuously without degrading reads |
| Query latency | Around 100 ms or less ("web time") | Scanning and aggregating large tables inside one page load |
| Query complexity | Filters, aggregations, and joins, not key lookups | Rules out key-value and cache-style stores |
| Query concurrency | Thousands of simultaneous user-initiated queries | Each query must be cheap, not just fast in isolation |
| Data retention | Years of history; raw tables of billions to trillions of rows | Distinguishes it from stream processing, which keeps bounded windows |

## How It Differs From Neighbouring Systems

| System | Freshness | Latency | Concurrency | History | Typical role |
| --- | --- | --- | --- | --- | --- |
| Transactional (OLTP) database | Immediate | Fast for row lookups, slow for large aggregations | High | Current state | System of record |
| Cloud data warehouse | Minutes to hours (batch or micro-batch loads) | Seconds | Tens of analysts | Unbounded | Internal BI and modelling |
| Stream processor (Flink, Kafka Streams, ksqlDB) | Sub-second | Results pushed, not queried ad hoc | n/a | Bounded windows and state | Continuous transforms, alerting |
| In-memory database | Immediate | Very fast | High | Limited by RAM | Caches, hot working sets |
| Real-time analytics database | Seconds | Milliseconds to sub-second | Thousands of queries | Years | User-facing and operational analytics |

The warehouse and real-time database often coexist: the warehouse remains the place for modelling
and ad hoc exploration, and the real-time database serves a narrower set of known, high-traffic
queries. Its usual upstream is a replayable log such as
[[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]].

## How They Meet the Requirements

**Columnar storage.** Each column is stored and compressed separately, so a query reads only the
columns it touches. ClickHouse adds per-column codecs (LZ4 by default, specialised ones such as
Gorilla for floats) and dictionary-encoded low-cardinality columns.

**Write-optimised ingestion.** Writes land as small immutable units that are merged or sealed in the
background, the same trade-off as a
[[concepts/data_structures/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]]:

- ClickHouse's MergeTree turns each insert into an immutable sorted *part* and merges parts in the
  background. Its authors describe it as LSM-inspired, though parts are not organised into levels.
- Pinot's real-time tables consume directly from Kafka, Pulsar, or Kinesis into in-memory *consuming
  segments* that are queryable immediately and later flushed as immutable completed segments.
- Druid makes streamed rows queryable on arrival and persists them as immutable segments copied to
  deep storage such as S3 or HDFS.

**Indexes that skip data.** ClickHouse keeps a sparse primary index with one entry per granule
(8,192 rows by default) small enough to stay in memory, plus *skipping indexes* (min-max, set, and
[[concepts/data_structures/bloom_filter|Bloom Filter]]) that rule out whole granules. Druid uses
compressed bitmap indexes (Roaring or CONCISE) for fast filtering. Pinot offers a menu of
per-column indexes, including inverted, sorted, range, and the pre-aggregating star-tree index.

**Pre-aggregation.** Answering from a summary instead of raw rows is the biggest latency and
concurrency lever. ClickHouse materialized views update incrementally as each new part is inserted;
Druid can summarise rows at ingestion time; Pinot's star-tree index pre-computes aggregates across
dimension combinations.

**Partition pruning.** Druid partitions every datasource by time first, so a query over the last
hour skips everything else; ClickHouse and Pinot partition and shard tables similarly. See
[[concepts/data_structures/data_structures_algorithms|Data Structures and Algorithms]] for the
underlying read/write/space trade-off.

**Vectorised, parallel execution.** ClickHouse processes columns in chunks with SIMD kernels chosen
at runtime, parallelising across cores and shards. Brokers in Druid and Pinot scatter a query to the
servers holding the relevant segments and merge the partial results.

**Approximation.** Druid ships bounded-memory approximate algorithms for count-distinct, ranking,
histograms, and quantiles, with exact versions when accuracy matters more than speed.

## Selection Criteria

| Criterion | What to look for |
| --- | --- |
| Ingestion throughput | Sustained millions of events per second without read degradation; native connectors to the event log |
| Read patterns | Efficient filtered aggregations over a few columns of a wide table, the dominant analytical shape |
| Query latency | Tens of milliseconds for the known query set; minimise how many nodes a single query fans out to |
| Concurrency | Throughput in queries per second under load, not single-query latency in isolation |
| Scalability | Horizontal scale-out for storage and queries, and separate scaling of ingestion and serving |
| Updates and deletes | Whether late-arriving corrections, upserts, and deletion requests are cheap, expensive, or unsupported |
| Joins | Whether the engine joins large tables well or expects denormalised data plus small lookup tables |
| Ease of use | SQL support, operational burden, and the availability of a managed service |

## The Main Engines

| | ClickHouse | Apache Druid | Apache Pinot |
| --- | --- | --- | --- |
| Origin | Yandex | Metamarkets | LinkedIn |
| Storage unit | Immutable parts, merged in the background | Immutable time-partitioned segments | Immutable segments; consuming segments for streams |
| Cluster shape | Shared-nothing shards and replicas, coordinated by Keeper (Raft, ZooKeeper-compatible) | Separate master, query, and data services; deep storage; SQL metadata store; ZooKeeper | Controller, broker, server, and minion, coordinated by Apache Helix on ZooKeeper |
| Distinctive strength | General SQL breadth, compression, incremental materialized views | Time-series event data, ingest-time summarisation, approximate aggregation | User-facing serving: rich per-column indexes, star-tree, upserts on streaming data |
| Stated fit | Broad OLAP, from logs to product analytics | Latency of about 100 ms to a few seconds; frequent inserts, rare updates | P95 as low as 10 ms and up to 100,000 queries per second, per its documentation |

Origins are general knowledge; the other rows come from each project's documentation.

## Limits and Trade-Offs

- **Updates are the weak spot.** Druid supports streaming inserts but not streaming updates, leaving
  corrections to background batch jobs. ClickHouse mutations rewrite whole parts and are
  non-atomic; its lightweight deletes only mark rows until a merge. Pinot assumes immutable data but
  supports upserts for streaming entity data.
- **Joins are limited.** Druid documents large fact-to-fact joins as a poor fit. ClickHouse supports
  hash, sort-merge, and other join algorithms, but its own paper (v24.6) lists missing join
  reordering and no correlated subqueries. Denormalising at ingestion is the usual answer.
- **Weaker transactional guarantees.** ClickHouse offers snapshot isolation, generally not full
  [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] statements; does
  not fsync inserts by default; and replicates asynchronously, so replicas are eventually consistent.
- **Operational weight.** Druid and Pinot clusters run several service types plus ZooKeeper, deep
  storage, and a metadata store. Managed services exist for all three engines and are often chosen
  for that reason.

## Open Questions & Disagreements

- The "~100 ms or less" latency target (from the Tinybird five-facet framing) is tighter than
  Druid's own documentation, which places its fit at roughly 100 ms to a few seconds and query
  latency at "sub-second to a few seconds", yet Druid is routinely listed as a real-time analytics
  database. Unresolved: whether 100 ms is a hard definitional bar or a target for the user-facing
  subset of workloads.
- The five-facet definition comes from a vendor (Tinybird, which builds on ClickHouse); no neutral,
  standards-style definition of a "real-time analytics database" was found.

## Related Concepts

- [[concepts/data_architecture/data_architecture|Data Architecture]] — places the real-time database in the serving layer, downstream of streaming ingestion
- [[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]] — the event log these databases most often ingest from directly
- [[concepts/data_structures/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — the write-optimised design that immutable parts and background merges borrow
- [[concepts/data_structures/bloom_filter|Bloom Filter]] — one of ClickHouse's data-skipping index types
- [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the guarantees these engines relax in exchange for ingest and scan speed
- [[concepts/data_engineering/stateful_vs_stateless_stream_processing|Stateful vs. Stateless Stream Processing]] — why bounded-window stream state differs from full-history query-time aggregation, and when to push state into this database instead

## References

- [ClickHouse: Lightning Fast Analytics for Everyone (VLDB 2024 paper overview)](https://clickhouse.com/docs/academic_overview)
- [Apache Druid: Introduction to Apache Druid](https://druid.apache.org/docs/latest/design/)
- [Apache Druid: Architecture](https://druid.apache.org/docs/latest/design/architecture/)
- [Apache Pinot: Architecture](https://docs.pinot.apache.org/basics/architecture)
- [Tinybird: ksqlDB alternative, on real-time analytics vs. stream processing](https://www.tinybird.co/blog-posts/ksqldb-alternative)
