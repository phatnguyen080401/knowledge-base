---
title: Apache Spark
tags: [data-engineering, distributed-systems, spark, overview]
created: 2026-10-22 10:50:05
updated: 2026-10-22 11:10:02
---

# Apache Spark

Spark is a distributed compute engine for processing data that does not fit, or does not finish, on one machine. It splits a dataset into partitions, builds a lazy graph of transformations over them, optimizes that graph, and executes it in parallel across a cluster — exposing the same engine through SQL, DataFrames, structured streaming, and machine-learning APIs. It owns the **compute** tier of a [[concepts/data_architecture/data_architecture|Data Architecture]], and unlike [[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] it is the thing doing the work rather than a layer pushing SQL into a warehouse.

## Why It Matters

- **It generalized MapReduce.** MapReduce wrote intermediate results to disk between every stage; Spark expresses a whole job as one DAG and keeps data in memory across stages, which is where its order-of-magnitude reputation came from.
- **One engine, several APIs.** Batch SQL, streaming, and ML run on the same execution core, so a streaming job and its batch backfill can share transformation code instead of being two implementations of one specification — the duplication the lambda architecture is criticized for.
- **It is storage-agnostic.** Spark has no storage layer of its own. It reads Parquet, ORC, Avro, JSON, and CSV from object storage, open table formats (Delta, Iceberg, Hudi), JDBC sources, and [[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]] — which is what lets it sit over a lake rather than inside a warehouse.
- **It handles what SQL cannot express.** Arbitrary Python or Scala per row, ML training, graph traversal, and unstructured input are the workloads that justify Spark over a warehouse that would otherwise do the job more cheaply.

## Architecture

| Component           | Responsibility                                                                             |
| ------------------- | -------------------------------------------------------------------------------------------- |
| **Driver**          | Runs the application's main logic, holds the `SparkSession`, plans the DAG, and schedules tasks. A single point of failure and the place where collected data lands |
| **Cluster manager** | Allocates executors: YARN, Kubernetes, or Spark's standalone manager                       |
| **Executor**        | A JVM on a worker node that runs tasks and holds cached partitions for the life of the application |
| **Task**            | The unit of work: one task per partition per stage, run on one executor core               |

The sizing identity that follows: **total parallelism = executors × cores per executor**, and a stage with fewer partitions than that leaves cores idle regardless of cluster size.

## The Execution Model

Spark's APIs layer over one core abstraction. The **RDD** is the original immutable, partitioned, lineage-tracked collection; the **DataFrame/Dataset** API is the one to use, because it is declarative enough to be optimized. RDDs remain the escape hatch for work the optimizer cannot see into.

Execution is lazy and splits cleanly into two kinds of call:

- **Transformations** (`select`, `filter`, `join`, `groupBy`) build the plan and do nothing.
- **Actions** (`count`, `collect`, `write`, `show`) trigger a **job**, which the scheduler cuts into **stages** at every shuffle boundary, each stage containing one **task per partition**.

The cut points are determined by dependency type:

- **Narrow dependency** — each output partition reads one input partition (`filter`, `map`, `union`). No data movement; stages pipeline these together.
- **Wide dependency** — an output partition reads many input partitions (`groupBy`, `join`, `distinct`, `repartition`). This forces a **shuffle**: data is written to disk, sent across the network, and re-read.

> [!important] The shuffle is the cost model
> Almost every Spark performance question reduces to how much data crosses the network and how evenly it is spread. Reading the DAG in the Spark UI and counting stage boundaries explains more than any configuration table.

## Catalyst and Adaptive Query Execution

The DataFrame API is declarative, so **Catalyst** — the query optimizer — rewrites it: predicate pushdown into the file reader, column pruning so only referenced columns leave storage, constant folding, and join reordering. **Tungsten** then generates JVM bytecode operating on a compact off-heap binary layout rather than boxed objects. This is why identical logic in DataFrames beats hand-written RDD code, and why a Python DataFrame job runs at the same speed as a Scala one: both compile to the same plan.

Static optimization relies on statistics that are usually wrong about intermediate results, so **Adaptive Query Execution** (default since Spark 3.0) re-optimizes mid-flight using the actual shuffle output:

- **Coalesces shuffle partitions**, fixing the perennial symptom of 200 tiny partitions from the `spark.sql.shuffle.partitions` default.
- **Switches join strategy** — promoting a sort-merge join to a broadcast hash join once a side turns out to be small.
- **Splits skewed partitions** so one oversized key does not serialize the stage.

Related, **dynamic partition pruning** uses a dimension-table filter to skip fact-table partitions at run time — the classic star-schema win.

## Partitions, Shuffles, and Skew

- **Partition sizing.** Aim for partitions in the low hundreds of megabytes. Too few wastes the cluster and risks spilling; too many drowns the scheduler in task overhead and produces the small-file problem downstream.
- **`repartition` vs. `coalesce`.** `repartition(n)` shuffles to get `n` even partitions; `coalesce(n)` merges partitions without a shuffle but only downward, and it propagates backward into the preceding stage's parallelism — a common cause of a job quietly running on one core.
- **Broadcast joins.** When one side fits in executor memory, broadcasting it removes the shuffle entirely. This is the single highest-value join optimization and the reason `broadcast()` hints still exist alongside AQE.
- **Skew.** One key holding a disproportionate share of rows means one task runs long after every other has finished. Fixes are AQE skew handling, salting the key, or isolating the hot keys and unioning the result — the same pathology as a hot Kafka partition.

## Memory and Caching

Executor memory is split between **execution** (shuffle, sort, join buffers) and **storage** (cached partitions), with each able to borrow from the other. Practical consequences:

- **Cache deliberately.** `cache()`/`persist()` pays off only when a DataFrame is reused several times; caching a once-read dataset just evicts something useful.
- **Spilling is a warning, not a failure.** Spark spills to disk rather than dying, so a job that "works" may be spending most of its time on disk I/O.
- **`collect()` runs on the driver.** Pulling a large result back is the most common out-of-memory cause, and it is a logic error rather than a tuning problem.

## Structured Streaming

Structured Streaming expresses a stream as an unbounded table: the same DataFrame operations, executed repeatedly over new data. By default it runs as **micro-batches**, giving latencies in the hundreds of milliseconds to seconds rather than the per-event latency of a true streaming engine like Flink.

- **Event time and watermarks.** Aggregation uses the event's own timestamp, and a watermark declares how late data may arrive before its window is finalized and its state dropped. Set it too tight and you lose records; too loose and state grows without bound.
- **Checkpointing.** Offsets and state go to a checkpoint directory; on restart, Spark resumes from it. This is why it pairs naturally with Kafka — recovery means replaying from a stored offset.
- **End-to-end exactly-once requires a replayable source and an idempotent sink.** Spark provides the middle; the sink's transactional or upsert behaviour provides the rest.

## Language APIs

Scala and Java run natively on the JVM. **PySpark** drives the same engine from Python, and as long as the work stays in DataFrame operations and Spark SQL, there is no Python in the data path and no performance penalty. The penalty appears with Python UDFs, which serialize every row to a Python worker process and back; **Arrow-based pandas UDFs** amortize this by passing columnar batches instead of rows. Those worker processes also sidestep the [[concepts/software_architecture/global_interpreter_lock|Global Interpreter Lock (GIL)]] — parallelism comes from separate processes, not threads. Spark SQL is a first-class API in its own right, and a `spark.sql(...)` string is planned identically to the equivalent DataFrame chain.

## When Not to Use It

- **The data is small.** A single machine with DuckDB, Polars, or pandas will finish before a cluster has started, without the distributed failure modes.
- **The work is SQL over data already in a warehouse.** Pushing it down with dbt is cheaper and far simpler to operate.
- **Latency must be per-event.** Micro-batching sets a floor; Flink is the right tool below it.
- **The access pattern is point lookups.** Spark scans; it is not an operational store, and no amount of tuning makes it one.

## Common Failure Modes

- **Driver out of memory** from `collect()`, `toPandas()`, or a broadcast of something that was not small.
- **One straggler task** per stage — nearly always key skew.
- **Small-file explosion** on write, from too many output partitions; fix at the write, not in the reader.
- **Non-deterministic ordering assumptions.** Partition order is not row order; without an `ORDER BY`, output order is an accident of the shuffle.
- **Silent correctness drift from type coercion.** Spark historically returned `null` for overflow and bad casts; ANSI SQL mode — the default from Spark 4.0 — raises errors instead, which is the safer behaviour but a real migration hazard for pipelines that depended on the old leniency.

## Related Concepts

- [[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]] — the usual streaming source, whose replayable offsets are what make Spark's checkpoint-and-restart recovery correct
- [[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] — the alternative for warehouse-SQL transformation; `dbt-spark` and [[concepts/data_engineering/dbt/dbt_databricks_adapter|dbt-databricks]] run dbt models on Spark itself
- [[concepts/data_architecture/data_architecture|Data Architecture]] — where the lake-versus-warehouse and batch-versus-streaming choices that lead to Spark are made
- [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — a failed Spark write leaves partial files unless an open table format puts a transaction log over object storage
- [[concepts/software_architecture/concurrency_and_parallelism|Concurrency and Parallelism]] — Spark is data parallelism across processes and machines; the same distinctions govern what a single executor can overlap
