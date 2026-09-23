---
title: Log-Structured Merge-Tree (LSM Tree)
tags:
  - data-structures
  - algorithms
created: 2026-09-23 13:30:09
updated: 2026-09-23 15:19:41
---

# Log-Structured Merge-Tree (LSM Tree)

An LSM tree is a write-optimized storage structure that never updates data in place: writes are buffered in a sorted in-memory table, flushed to disk as immutable sorted files, and merged in the background. It converts random writes into sequential ones, which is the opposite trade-off to the [[concepts/b_plus_tree|B+ Tree]] and the reason it underpins modern write-heavy stores (see [[concepts/data_structures_algorithms|Data Structures and Algorithms]]).

## Why It Matters

- **Sequential writes are an order of magnitude faster than random ones** on both spinning disks and SSDs, and they avoid the erase-block churn that wears flash out.
- It is the engine behind Cassandra, ScyllaDB, HBase, RocksDB, LevelDB, and the storage layer of many time-series and streaming systems — so its behaviour is *why* those systems have the performance profile they do.
- It makes read cost a tunable rather than a constant, and shows how compaction policy, [[concepts/bloom_filter|Bloom Filter]] sizing, and caching combine to buy that read performance back.

## The Write Path

```text
write ──> WAL (append, for durability)
     └──> Memtable (sorted, in memory)
              │ full?
              ▼
          flush as an immutable SSTable ──> Level 0
                                              │ compaction
                                              ▼
                                       Level 1, 2, 3 ... (larger, older)
```

1. **Write-ahead log.** Every write is appended to a sequential log first, so an unflushed memtable can be replayed after a crash.
2. **Memtable.** The write is applied to a sorted in-memory structure — usually a skip list or a red-black tree, because both keep keys ordered under concurrent inserts.
3. **Flush.** When the memtable exceeds its size threshold it becomes immutable, a new one takes over, and the old one is written out sequentially as an **SSTable** (Sorted String Table): a file of key-value pairs in sorted order, with a sparse index and a Bloom filter alongside it.
4. **Compaction.** A background process merges SSTables, discarding superseded versions and deletion markers.

**Nothing is ever modified.** An update is a new version of the key with a higher sequence number; a delete writes a **tombstone**. The newest version wins, and the old ones are reclaimed only by compaction.

## The Read Path

A read must find the newest version of a key, so it searches newest-to-oldest:

1. The active memtable, then any immutable memtables awaiting flush.
2. The block cache.
3. Each candidate SSTable, newest level first. For each one: check its **Bloom filter** first — if it says "definitely absent", skip the file entirely; otherwise use the sparse index to locate the right block and read only that block.

Bloom filters are what make this affordable: without them, a read for a nonexistent key would have to open every file. With a 1% filter, roughly 99% of those useless reads are eliminated.

## Compaction Strategies

Compaction is where the whole design is tuned. The two archetypes:

| | **Leveled** | **Size-tiered (Tiered)** |
| --- | --- | --- |
| Layout | Each level holds non-overlapping SSTables, ~10× larger than the level above | Each tier holds several similarly sized, freely overlapping SSTables |
| Merge trigger | Level exceeds its size budget | Enough same-size files accumulate |
| Read amplification | Low — at most one file per level | High — many overlapping files may hold the key |
| Write amplification | High — a key is rewritten at every level | Low |
| Space amplification | Low (~10%) | High — up to 2× during a merge of the largest tier |
| Used by | RocksDB (default), LevelDB | Cassandra (default), ScyllaDB |

Other policies exist for specific shapes of workload: **FIFO/time-window** compaction for time-series with TTLs (drop whole old files, never merge them), and **universal/hybrid** policies that sit between the two archetypes.

## The Three Amplifications

Every LSM discussion reduces to balancing these, and you can only ever pick two (the RUM conjecture):

- **Write amplification** — bytes written to disk per byte of user data. Leveled compaction can rewrite a key 10–30 times over its lifetime.
- **Read amplification** — blocks read per logical read. Grows with the number of levels and the overlap between files.
- **Space amplification** — disk used per byte of live data. Obsolete versions and tombstones persist until compaction removes them.

> [!tip] The one-line summary
> Leveled compaction trades write amplification for read and space efficiency; tiered compaction trades read and space efficiency for write throughput.

## Operational Realities

- **Tombstones are not free.** A delete adds data. It can only be dropped once it has been compacted past every SSTable that might contain an older version of the key — hence Cassandra's `gc_grace_seconds` and the classic failure mode where scanning a range full of tombstones times out.
- **Compaction competes with foreground traffic** for disk bandwidth and CPU. Under sustained heavy ingest, compaction falls behind, Level 0 accumulates files, read amplification spikes, and the engine eventually throttles or stalls writes.
- **Range scans require a merge.** A scan must merge iterators from the memtable and every overlapping SSTable, so it is more expensive than the pure leaf-list walk of a B+ tree.
- **Point reads for missing keys** are the cheap case with Bloom filters and the pathological case without them.
- **Space must be provisioned for compaction**, which temporarily needs room for both the inputs and the output.

## LSM Tree vs. B+ Tree

| | LSM Tree | B+ Tree |
| --- | --- | --- |
| Write pattern | Sequential appends + background merges | Random in-place page updates |
| Write throughput | High and fairly flat | Lower, bounded by random I/O |
| Read latency | Variable; depends on level count and filters | Predictable; one descent |
| Range scans | Merge across levels | Sequential leaf walk |
| Space | Temporary bloat from dead versions | Partially filled pages |
| Concurrency | Immutable files simplify snapshots and MVCC | Requires careful latching |
| Best for | Ingest-heavy, time-series, event logs | Transactional and mixed workloads |

## Related Concepts

- [[concepts/b_plus_tree|B+ Tree]] — the read-optimized alternative this structure is always contrasted with
- [[concepts/bloom_filter|Bloom Filter]] — the component that keeps LSM read amplification survivable
- [[concepts/data_structures_algorithms|Data Structures and Algorithms]] — the read/write/space trade-off this structure is an extreme point of
- [[concepts/data_architecture|Data Architecture]] — choosing an LSM-backed store is a platform-level architectural commitment

## References

- O'Neil, Cheng, Gawlick, O'Neil — [The Log-Structured Merge-Tree](https://www.cs.umb.edu/~poneil/lsmtree.pdf) (1996)
- Chang et al. — *Bigtable: A Distributed Storage System for Structured Data* (2006)
- Martin Kleppmann — *Designing Data-Intensive Applications*, ch. 3
- [RocksDB Wiki: Compaction](https://github.com/facebook/rocksdb/wiki/Compaction)
