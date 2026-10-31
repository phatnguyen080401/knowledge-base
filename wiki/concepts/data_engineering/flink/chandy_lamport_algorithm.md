---
title: Chandy-Lamport Algorithm
tags: [data-engineering, distributed-systems, fault-tolerance, flink]
created: 2026-10-31 10:36:57
updated: 2026-10-31 11:18:27
---

# Chandy-Lamport Algorithm

The Chandy-Lamport algorithm records a consistent global snapshot of a distributed system, meaning every process's state plus the messages in flight, without stopping it. Marker messages flow along the same channels as the data. [[concepts/data_engineering/flink/apache_flink|Apache Flink]] adapts it as [[concepts/data_engineering/flink/asynchronous_barrier_snapshotting|Asynchronous Barrier Snapshotting (ABS)]], the mechanism behind its checkpoints and exactly-once state.

## Why It Matters

A streaming job is many parallel operators exchanging records over the network, each holding state. To recover from a crash, the job needs a saved state from which it can resume as if nothing had failed. Saving each operator's state at "the same time" is impossible without a global clock, and pausing the whole job to save it would stall the stream.

The danger of an inconsistent snapshot is concrete. Say an operator's count is saved *after* it processed a record, but the source's offset is saved *before* that record was read. On recovery the record is replayed and counted twice. The snapshot has to be a **consistent cut**: if it includes the effect of a record, it also includes that record having been sent. Chandy-Lamport produces such a cut while the system keeps running.

## The Original Algorithm

K. Mani Chandy and Leslie Lamport published the algorithm in 1985. It assumes processes connected by reliable, **FIFO** channels, so that messages on one channel arrive in order and none are lost.

1. **Initiate.** Any process records its own state, then sends a **marker** on every outgoing channel before sending anything else.
2. **First marker received.** When a process receives a marker on channel *c* and has not yet recorded its state, it records its state, records *c* as empty, and sends markers on all of its outgoing channels. It then starts recording the messages that arrive on each of its *other* incoming channels.
3. **Later markers.** When a marker arrives on a channel the process is still recording, it stops recording that channel. The channel's state is the list of messages that arrived on it between the process's own state record and this marker.
4. **Terminate.** The snapshot is complete when every process has received a marker on every incoming channel.

Because channels are FIFO, a marker separates the messages a channel carried *before* the sender's snapshot from those it carried *after*. Every message is therefore either already reflected in the receiver's recorded state, recorded as in flight on the channel, or entirely after the cut. The global state that results may never have existed at any single instant, but it is consistent, and the real execution could have passed through it.

## How Flink Adapts It

Flink's version, **Asynchronous Barrier Snapshotting (ABS)**, turns markers into numbered checkpoint barriers and has each multi-input operator *align* on them, so in an acyclic dataflow no channel state needs recording. Unaligned checkpoints bring channel recording back to cope with backpressure. The full mechanism, delivery modes, recovery, savepoints, and configuration are in [[concepts/data_engineering/flink/asynchronous_barrier_snapshotting|Asynchronous Barrier Snapshotting (ABS)]].

## Related Concepts

- [[concepts/data_engineering/flink/asynchronous_barrier_snapshotting|Asynchronous Barrier Snapshotting (ABS)]] — Flink's adaptation in full: alignment, async and unaligned checkpoints, recovery, savepoints
- [[concepts/data_engineering/flink/apache_flink|Apache Flink]] — the engine: architecture, APIs, state backends, and where checkpointing fits operationally
- [[concepts/data_engineering/stateful_vs_stateless_stream_processing|Stateful vs. Stateless Stream Processing]] — why consistent snapshots are needed at all, and how Kafka Streams and Spark achieve the same guarantee differently
- [[concepts/databases/write_ahead_log|Write-Ahead Log (WAL)]] — the contrasting recovery approach of logging every change, which Spark's offset log uses instead of a distributed snapshot
- [[concepts/databases/distributed_consensus|Distributed Consensus]] — another foundational distributed-systems problem: agreeing on a value, as opposed to observing a consistent global state

## References

- K. M. Chandy and L. Lamport, "Distributed Snapshots: Determining Global States of Distributed Systems," *ACM Transactions on Computer Systems*, 1985.
- P. Carbone et al., "Lightweight Asynchronous Snapshots for Distributed Dataflows," arXiv:1506.08603, 2015.
