---
title: B+ Tree
tags: [data-structures, algorithms]
created: 2026-09-23 13:30:09
updated: 2026-09-24 11:51:57
---

# B+ Tree

A B+ tree is a variant of the [[concepts/b_tree|B-Tree]] in which **all records live in the leaf level** and internal nodes hold only separator keys, with the leaves chained together in a sorted linked list. That one change makes internal nodes denser and range scans nearly free, which is why it — and not the plain B-tree — is the index structure shipped by virtually every relational database (see [[concepts/data_structures_algorithms|Data Structures and Algorithms]]).

## Why It Matters

- It is the default answer to "how is a database index implemented?" — PostgreSQL, MySQL/InnoDB, Oracle, SQL Server, and SQLite all use it.
- It explains, directly, why `WHERE created_at BETWEEN ... AND ...` is fast, why a covering index avoids touching the table, and why InnoDB primary keys should be monotonically increasing.
- It is the read-optimized pole of the trade-off whose opposite pole is the [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]].

## The Two Changes from a B-Tree

### 1. Values only in leaves

Internal nodes store separator keys and child pointers, nothing else. Since a separator is just a key, more of them fit in a page, so the fan-out rises — often from a few hundred to a thousand or more — and the tree loses a level. Every lookup now descends all the way to a leaf, so lookup cost is uniform and predictable: exactly the height of the tree in block reads.

A useful consequence: the separator keys need not be real keys at all, merely values that route correctly. Implementations exploit this by storing truncated prefixes ("suffix truncation"), raising fan-out further.

### 2. Leaves linked in sequence

Each leaf holds a pointer to its right neighbour (often both neighbours). A range query descends once to find the lower bound, then walks the linked list sequentially until the upper bound — no traversal back up through the tree, and largely sequential I/O.

```text
Internal:        [ 20 | 50 ]            <- separators only
                /      |     \
Leaves:  [5,10,15] -> [20,30,40] -> [50,60,85]   -> next...
         (each leaf holds keys AND values, and points to the next leaf)
```

## Operations

| Operation | Cost | Notes |
| --- | --- | --- |
| Point lookup | $O(\log_B n)$, always to leaf depth | 3–4 page reads for a billion keys |
| Range scan of $k$ rows | $O(\log_B n + k/\text{rows per leaf})$ | Sequential leaf walk |
| Insert | $O(\log_B n)$ | Split leaf, copy separator up |
| Delete | $O(\log_B n)$ | Borrow/merge; many engines just leave the slot free |
| Full ordered scan | $O(n)$ | Walk the leaf list; no tree traversal |

**Insert** works as in a B-tree, with one difference: when a leaf splits, the median key is *copied* up as a separator rather than moved, because the record itself must remain in a leaf. When an internal node splits, the median is moved up as usual.

**Delete** in practice is often lazy. Rather than rebalancing eagerly, engines mark the entry dead and leave the page underfull, reclaiming space during a later vacuum or page reorganization — rebalancing on every delete is expensive and usually unnecessary.

## Why Databases Chose It

- **Range and ordered access.** `BETWEEN`, `ORDER BY`, `GROUP BY`, `MIN`/`MAX`, and merge joins all become a leaf-list walk. A hash index can do none of this.
- **Predictable latency.** Every lookup costs the same number of I/Os, which makes query-plan costing meaningful.
- **Self-balancing under arbitrary insert order** without the global rewrite that a sorted file would need.
- **Cache-friendly.** The upper levels of the tree are small and stay pinned in the buffer pool, so in practice only the leaf read hits disk.

### Clustered vs. secondary indexes

- A **clustered index** stores the full row in the leaf, so the table *is* the B+ tree (InnoDB's primary key). Point lookups need no second hop, but the leaf entries are large, so fewer rows fit per page.
- A **secondary index** stores the indexed columns plus a reference to the row — a primary key in InnoDB, a physical tuple pointer (`ctid`) in PostgreSQL. In InnoDB a secondary-index lookup therefore costs two descents, unless the index is **covering** (contains every column the query needs) and the second descent can be skipped.

## Operational Consequences Worth Knowing

- **Insert sequentially when you can.** Monotonic keys always append to the rightmost leaf, packing pages near 100% and producing one hot page. Random keys (UUIDv4) scatter inserts across the whole index, causing page splits, ~70% occupancy, and a much larger index. UUIDv7 or ULID restores the monotonic property.
- **Index size is not free.** Every secondary index is another B+ tree that must be maintained on every write. This is the concrete cost behind "don't index every column".
- **Left-prefix rule.** A composite index on `(a, b, c)` orders leaves by `a`, then `b`, then `c`, so it can serve predicates on `a`, on `(a, b)`, and on `(a, b, c)` — but not on `b` alone.
- **Concurrency.** Real implementations use B-link trees (Lehman & Yao): each node carries a high key and a right-link, so a reader that arrives during a split can follow the link sideways instead of holding a lock on the parent. PostgreSQL's `nbtree` is exactly this.
- **In-place updates need protecting.** Because pages are overwritten rather than appended, a power loss mid-write can tear a page. Engines guard against this in the write-ahead log — PostgreSQL writes a full page image after each checkpoint — which is a significant part of why B+ tree write amplification is what it is. See [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]].

## B+ Tree vs. LSM Tree

| | B+ Tree | LSM Tree |
| --- | --- | --- |
| Write path | Update the page in place | Append to memory, flush, compact later |
| Write throughput | Bounded by random page writes | Much higher; writes are sequential |
| Read cost | One descent, predictable | May probe several levels |
| Range scans | Excellent (leaf list) | Good, but requires a merge across levels |
| Space overhead | Partially filled pages | Obsolete versions until compaction |
| Fits | Transactional, mixed read/write workloads | Ingest-heavy, time-series, write-dominated |

## Related Concepts

- [[concepts/b_tree|B-Tree]] — the parent structure this refines by relocating values to the leaves
- [[concepts/data_structures_algorithms|Data Structures and Algorithms]] — the comparison of this against the write-optimized alternatives
- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — the structure chosen when write throughput outranks read predictability
- [[concepts/data_architecture|Data Architecture]] — index strategy is part of the physical design layer
- [[concepts/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — why this structure is the default for transactional workloads, and what its in-place writes cost the recovery log

## References

- Comer — [The Ubiquitous B-Tree](https://dl.acm.org/doi/10.1145/356770.356776), ACM Computing Surveys (1979)
- Lehman, Yao — *Efficient Locking for Concurrent Operations on B-Trees* (1981)
- Alex Petrov — *Database Internals*, ch. 2–4
- [PostgreSQL documentation: B-Tree indexes](https://www.postgresql.org/docs/current/btree.html)
