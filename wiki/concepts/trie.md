---
title: Trie (Prefix Tree)
tags: [data-structures, algorithms]
created: 2026-09-23 13:30:09
updated: 2026-09-24 11:51:57
---

# Trie (Prefix Tree)

A trie is a tree in which a key is represented by the **path from the root to a node**, one symbol per edge, rather than by a value stored inside a node. Lookup therefore costs $O(L)$ in the key length and is completely independent of how many keys the structure holds — the property that makes it the natural choice for prefix queries among the structures in [[concepts/data_structures_algorithms|Data Structures and Algorithms]].

The name comes from *re**trie**val*, which is why it is often pronounced "tree" even though "try" is the common usage.

## Why It Matters

- **Prefix queries are native.** "All keys starting with `dat`" is a descent to one node followed by a subtree traversal. A [[concepts/b_plus_tree|B+ Tree]] can approximate this; a hash index cannot do it at all.
- **Lookup does not degrade as the dataset grows** — unlike comparison-based trees, where height grows with $n$.
- **Common prefixes are stored once**, which for dictionaries, URLs, and IP prefixes is a large saving.
- Its practical descendants — radix trees and adaptive radix trees — are used inside routers, databases, and in-memory indexes where cache behaviour matters.

## Structure

Each node has up to $R$ children, one per symbol in the alphabet (26 for lowercase letters, 256 for bytes), plus a flag marking whether the path ending at that node is a complete key. The root represents the empty string.

```text
        (root)
        /    \
       c      d
       |      |
       a      a
      / \     |
     t   r    t
    [*] [*]   |
               a
              [*]
   keys: "cat", "car", "data"     [*] = end of key
```

- `cat` and `car` share the path `c → a` and diverge only at the last symbol.
- The character `t` is never stored as a value; it is the *edge* that was taken.

## Operations

| Operation | Complexity | Notes |
| --- | --- | --- |
| Insert | $O(L)$ | Walk or create one node per symbol |
| Lookup | $O(L)$ | Independent of $n$ |
| Delete | $O(L)$ | Unset the end-of-key flag; prune nodes with no other children |
| Prefix match | $O(L)$ to the prefix node | Then traverse the subtree for the matches |
| Enumerate in sorted order | $O(n \cdot L)$ | Depth-first traversal visits keys lexicographically |
| Space | $O(n \cdot L \cdot R)$ worst case | The weakness — see below |

**Delete** is the subtle one: you cannot simply remove the path, because a prefix of the deleted key may itself be a key (deleting `car` must not destroy `ca` or `cat`). Clear the terminal flag, then prune bottom-up only while a node has no children and is not itself a key.

## The Space Problem, and Its Fixes

A naive trie allocates an $R$-slot child array in every node. With $R = 256$ and mostly sparse nodes, the pointer overhead dwarfs the keys — a trie can easily use more memory than simply storing the strings. Every practical variant attacks this:

| Variant | Idea | Trade-off |
| --- | --- | --- |
| **Compressed trie / radix tree (PATRICIA)** | Collapse each chain of single-child nodes into one edge labelled with a substring | Far fewer nodes; slightly more complex splitting on insert |
| **Ternary search tree** | Each node has three children (`<`, `=`, `>`) instead of $R$ | Near-hash-table speed at a fraction of the space; slower than an array trie |
| **Adaptive radix tree (ART)** | Node size adapts to the actual number of children (4, 16, 48, 256) | Cache-efficient; used in HyPer and DuckDB as a main-memory index |
| **DAWG / DAFSA** | Merge identical *suffixes* too, making it a DAG rather than a tree | Very compact for fixed dictionaries; no per-key payload, hard to update |
| **Succinct trie (LOUDS)** | Encode the topology as a bit vector | Near information-theoretic minimum space; read-only |

## Related String Structures

- **Suffix tree** — a compressed trie of every suffix of a single string; solves substring search in $O(L)$ after $O(n)$ construction. Suffix *arrays* are the practical, space-efficient stand-in.
- **Aho–Corasick automaton** — a trie of many patterns augmented with failure links, matching all of them against a text in a single pass. The structure behind classic multi-keyword scanners and intrusion-detection rule matching.

## Where It Is Used

- **Autocomplete and type-ahead search** — the canonical use: descend to the typed prefix, then rank the subtree.
- **IP routing tables** — longest-prefix match over binary address prefixes; routers use radix tries (and hardware variants) for exactly this.
- **Spell checking and dictionary lookup**, including fuzzy matching by walking the trie with an edit-distance budget.
- **In-memory database indexes** — ART and its relatives, where cache misses, not disk I/O, are the bottleneck.
- **Key namespacing** — routing keys by prefix in distributed stores and object storage.

## Trie vs. Hash Table vs. B+ Tree

| | Trie | Hash table | B+ Tree |
| --- | --- | --- | --- |
| Lookup | $O(L)$ | $O(1)$ average, $O(L)$ to hash the key | $O(\log_B n)$ |
| Prefix query | Native | Impossible | Range scan over a sorted prefix |
| Ordered traversal | Yes, lexicographic | No | Yes |
| Worst case | No degradation with $n$ | Collision-dependent | Guaranteed logarithmic |
| Space | High without compression | Moderate | Moderate; page-oriented |
| On disk | Poor fit (pointer chasing) | Poor for ranges | Designed for it |

Note that a hash lookup is not truly $O(1)$ for string keys — it must read the whole key to hash it, so it is $O(L)$ too. The trie's real advantage is not raw speed but the prefix structure it preserves.

## Related Concepts

- [[concepts/data_structures_algorithms|Data Structures and Algorithms]] — positions the trie against comparison-based and hash-based alternatives
- [[concepts/b_plus_tree|B+ Tree]] — the disk-oriented ordered index; the trie is its in-memory, prefix-oriented counterpart
- [[concepts/bloom_filter|Bloom Filter]] — the other structure chosen for membership questions, when only an approximate answer is needed
- [[concepts/master_data_management|Master Data Management (MDM)]] — entity resolution and fuzzy name matching lean on tries and their edit-distance traversals

## References

- Fredkin — *Trie Memory*, Communications of the ACM (1960)
- Morrison — *PATRICIA: Practical Algorithm to Retrieve Information Coded in Alphanumeric* (1968)
- Leis, Kemper, Neumann — [The Adaptive Radix Tree](https://db.in.tum.de/~leis/papers/ART.pdf) (2013)
- Sedgewick, Wayne — *Algorithms*, 4th ed., ch. 5.2 (Tries)
