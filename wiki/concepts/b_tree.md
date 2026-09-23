---
title: B-Tree
tags:
  - data-structures
  - algorithms
created: 2026-09-23 13:30:09
updated: 2026-09-23 15:19:41
---

# B-Tree

A B-tree is a self-balancing search tree in which every node holds many keys and has many children, so the tree stays extremely shallow and a lookup costs only a handful of block reads. Introduced by Rudolf Bayer and Edward McCreight in 1970, it is the canonical disk-oriented member of the family described in [[concepts/data_structures_algorithms|Data Structures and Algorithms]].

## Why It Matters

- It is the structure that made indexed access to data larger than memory practical, and it still backs most file systems and traditional relational indexes.
- It is the reference point for the whole field: the [[concepts/b_plus_tree|B+ Tree]] is a refinement of it, and the [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] exists precisely as an answer to its write behaviour.
- Its design encodes the single most important lesson about storage: **match the node size to the unit of I/O.**

## The Core Idea

A binary search tree over a billion keys is about 30 levels deep. On disk, each level is a separate random read — 30 I/Os per lookup. A B-tree fixes this by widening each node to fill one disk page (typically 4–16 KB), so a node holds hundreds of keys and has hundreds of children.

With a fan-out $B$, the height is $\log_B n$ rather than $\log_2 n$:

$$
\text{height} \approx \log_{500}(10^9) \approx 3.5
$$

Three or four block reads instead of thirty. The structure is not asymptotically better — it is better by a constant factor of roughly $\log_2 B$, and that constant is what matters.

## Structure and Invariants

A B-tree of order $m$ satisfies:

- Every node holds at most $m - 1$ keys, in sorted order, and at most $m$ child pointers.
- Every node except the root holds at least $\lceil m/2 \rceil - 1$ keys — nodes are guaranteed at least half full.
- A node with $j$ keys has exactly $j + 1$ children; the keys act as separators, and the $i$-th child contains all keys between separator $i-1$ and separator $i$.
- **All leaves are at the same depth.** Balance is maintained by construction, not by rotation after the fact.
- In a classic B-tree, payload values may live in *any* node, internal or leaf — this is the key difference from the [[concepts/b_plus_tree|B+ Tree]].

```text
                  [ 20 | 50 ]
                 /     |     \
      [5|10|15]  [25|30|40]   [60|70|85|90]
```

## Operations

### Search

Start at the root, binary-search the keys within the node to find the right child pointer, descend, repeat. One node per level, so $O(\log_B n)$ block reads and $O(\log_2 B)$ comparisons per node.

### Insert — split on overflow

1. Descend to the correct leaf and insert the key in sorted position.
2. If the node now has $m$ keys it **overflows**: split it into two half-full nodes and promote the median key into the parent.
3. If the parent overflows too, split recursively. If the root splits, a new root is created — **this is the only way a B-tree grows in height**, which is why it grows at the top and stays balanced.

### Delete — merge or borrow on underflow

1. Remove the key; if it is in an internal node, replace it with its in-order predecessor or successor from a leaf.
2. If the node drops below $\lceil m/2 \rceil - 1$ keys it **underflows**: borrow a key from an adjacent sibling through the parent, or, if no sibling can spare one, merge the node with a sibling and pull the separator down.
3. Merging may cascade upward; if the root ends up with no keys, it is removed and the tree shrinks by one level.

| Operation | Complexity | Dominant cost |
| --- | --- | --- |
| Search | $O(\log_B n)$ | One page read per level |
| Insert | $O(\log_B n)$ | Page read per level + rewrite on split |
| Delete | $O(\log_B n)$ | Page read per level + rewrite on merge |
| Space | $O(n)$ | At least 50% node occupancy guaranteed |

## Behaviour on Real Storage

- **Write amplification.** Changing one 20-byte row rewrites the whole 8 KB page. A split rewrites three pages. This is inherent to update-in-place and is the main motivation for log-structured designs.
- **Crash safety needs a log.** A split touches several pages that must all survive or all fail; databases therefore pair the B-tree with a write-ahead log (WAL) so a torn split can be repaired on restart.
- **Fragmentation.** Random inserts leave pages around 70% full on average, so an index is typically larger than the data it indexes and benefits from periodic rebuilds. Sequential (monotonic) keys append to the rightmost leaf and pack near 100% — one concrete reason to prefer sequential over random UUID primary keys.
- **Concurrency.** Naive latching of a whole root-to-leaf path serializes all traffic. Real implementations use latch crabbing (release the parent as soon as the child is known safe) or B-link trees, which add a right-sibling pointer so a reader can still find a key that moved during a concurrent split.

## Where It Is Used

- File systems: NTFS, HFS+, Btrfs, ext4 directory indexes.
- Database indexes, though almost every relational engine actually ships the B+ tree variant.
- Key-value stores that favour reads and in-place updates, such as LMDB and BerkeleyDB.

## B-Tree vs. B+ Tree

| | B-Tree | B+ Tree |
| --- | --- | --- |
| Where values live | Any node | Leaves only |
| Internal node fan-out | Lower (values consume space) | Higher (separator keys only) |
| Best-case lookup | Can stop early at an internal node | Always descends to a leaf |
| Range scan | Requires in-order traversal up and down | Follow the linked leaf list |
| Typical use today | File systems | Database indexes |

## Related Concepts

- [[concepts/data_structures_algorithms|Data Structures and Algorithms]] — the overview that positions the B-tree against the alternatives
- [[concepts/b_plus_tree|B+ Tree]] — the variant that moves all values to the leaves and links them for range scans
- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — the write-optimized alternative that avoids update-in-place entirely
- [[concepts/trie|Trie (Prefix Tree)]] — a different answer to the same question, keyed by position in the string rather than by comparison

## References

- Bayer, McCreight — *Organization and Maintenance of Large Ordered Indices* (1970)
- Comer — [The Ubiquitous B-Tree](https://dl.acm.org/doi/10.1145/356770.356776), ACM Computing Surveys (1979)
- Graefe — *Modern B-Tree Techniques* (2011)
