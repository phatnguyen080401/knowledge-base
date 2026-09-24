---
title: Data Structures and Algorithms
tags: [data-structures, algorithms]
created: 2026-09-23 13:30:09
updated: 2026-09-24 11:51:57
---

# Data Structures and Algorithms

A data structure is a concrete arrangement of data in memory or on disk, together with the algorithms that read and modify it. In a data system the choice of structure is an architectural decision, not an implementation detail: it fixes the latency, throughput, and storage cost of every query the system will ever serve, which is why it belongs to [[concepts/data_architecture|Data Architecture]].

## Why It Matters

- **It decides what is fast.** A B+ tree makes range scans cheap and random writes expensive; an LSM tree does the opposite. No amount of tuning reverses that.
- **It is the hardest thing to change later.** Query syntax, schemas, and APIs can be migrated; the storage engine underneath a petabyte of data effectively cannot.
- **It explains engine behaviour.** "Why is Cassandra fast at writes but variable at reads?" and "why does PostgreSQL slow down on random UUID primary keys?" are both answered by the underlying structure.

## The Central Trade-off

Nearly every storage structure trades three quantities against each other — the **RUM conjecture** (Read, Update, Memory): you may optimize any two at the expense of the third.

| Amplification | Meaning | Worst in |
| --- | --- | --- |
| **Read** | Extra data read per logical read | LSM trees (many overlapping files) |
| **Write** | Extra bytes written per logical write | B-trees (full-page writes) and LSM compaction |
| **Space** | Extra storage per logical byte | LSM trees (obsolete versions), tries (pointer overhead) |

A second, older trade-off governs everything on disk: **the unit of I/O is a block, not a byte.** Structures designed for disk maximize the useful work done per block read — which is exactly why B-trees have a fan-out of hundreds rather than two.

## The Structures

| Structure | Optimized for | Core idea | Typical home |
| --- | --- | --- | --- |
| [[concepts/b_tree\|B-Tree]] | Balanced reads and writes on block storage | Wide, shallow, always-balanced search tree | File systems, classic DB indexes |
| [[concepts/b_plus_tree\|B+ Tree]] | Point lookups **and** range scans | B-tree with all records in linked leaves | Nearly every relational index |
| [[concepts/bloom_filter\|Bloom Filter]] | Avoiding work | Probabilistic "definitely not present / maybe present" | LSM engines, caches, dedup |
| [[concepts/lsm_tree\|Log-Structured Merge-Tree (LSM Tree)]] | Write throughput | Buffer in memory, flush sorted files, compact later | Cassandra, RocksDB, HBase |
| [[concepts/trie\|Trie (Prefix Tree)]] | Prefix and string queries | Key is the path from the root | Autocomplete, IP routing |

## Complexity at a Glance

$n$ = number of keys, $L$ = key length, $B$ = branching factor (fan-out).

| Operation | B-Tree / B+ Tree | LSM Tree | Hash index | Trie |
| --- | --- | --- | --- | --- |
| Point lookup | $O(\log_B n)$ | $O(\log_B n)$ amortized, multiplied by the number of levels probed | $O(1)$ average | $O(L)$ |
| Range scan | $O(\log_B n + k)$ | Merge across levels | Not supported | Prefix-ordered traversal |
| Insert | $O(\log_B n)$, in place | $O(1)$ into memtable, cost deferred to compaction | $O(1)$ average | $O(L)$ |
| Membership test | Exact | Exact | Exact | Exact |

A [[concepts/bloom_filter|Bloom Filter]] sits outside this table on purpose: it answers only approximate membership, in $O(k)$ with $k$ hash functions, and exists to stop the other structures from doing unnecessary work.

## How to Choose

1. **Characterize the workload first.** Read-heavy or write-heavy? Point lookups or ranges? Sequential keys or random ones? Everything else follows.
2. **Write-heavy, append-mostly, tolerant of read variance** → LSM tree.
3. **Mixed workload with range scans and transactional updates** → B+ tree.
4. **Exact key, no ordering needed, fits in memory** → hash index.
5. **Queries are by prefix or over strings** → trie or radix tree.
6. **Lookups often miss** → put a Bloom filter in front of whatever you chose.

## Related Concepts

- [[concepts/data_architecture|Data Architecture]] — the parent discipline; storage-engine choice is one of its structural decisions
- [[concepts/b_tree|B-Tree]] — the baseline disk-oriented index every other structure is compared against
- [[concepts/b_plus_tree|B+ Tree]] — the refinement of the B-tree that relational databases actually ship
- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — the write-optimized alternative to the B+ tree
- [[concepts/bloom_filter|Bloom Filter]] — the auxiliary structure that makes LSM reads affordable
- [[concepts/trie|Trie (Prefix Tree)]] — the structure to reach for when the query is a prefix
- [[concepts/api_integration_protocols|API and Integration Protocols]] — the same "pick the interaction style first" reasoning applied at the system boundary rather than the storage layer

## References

- Cormen, Leiserson, Rivest, Stein — *Introduction to Algorithms*, 3rd ed., ch. 18 (B-Trees)
- Martin Kleppmann — *Designing Data-Intensive Applications*, ch. 3 ("Storage and Retrieval")
- Alex Petrov — *Database Internals*, parts I–II
- Athanassoulis et al. — [Designing Access Methods: The RUM Conjecture](https://stratos.seas.harvard.edu/publications/designing-access-methods-rum-conjecture)
