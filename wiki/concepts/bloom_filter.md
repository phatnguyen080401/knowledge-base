---
title: Bloom Filter
tags: [data-structures, algorithms]
created: 2026-09-23 13:30:09
updated: 2026-09-24 11:51:57
---

# Bloom Filter

A Bloom filter is a space-efficient probabilistic data structure that answers one question — "is this element in the set?" — with two possible answers: **definitely not**, or **probably yes**. It never produces a false negative, and in exchange for a tunable false-positive rate it uses a tiny fraction of the memory a real set would need, which is why it appears wherever a lookup is expensive enough to be worth avoiding (see [[concepts/data_structures_algorithms|Data Structures and Algorithms]]).

## Why It Matters

- It converts an expensive miss into a cheap one. In an [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]], checking a Bloom filter in RAM saves reading an SSTable from disk — this is the single optimization that makes LSM reads viable.
- It scales where exact structures do not: roughly **10 bits per element for a 1% false-positive rate**, regardless of how large the elements themselves are.
- It is the standard introduction to probabilistic structures and to the idea of trading correctness bounds for resources.

## How It Works

A Bloom filter is an array of $m$ bits, all initially 0, plus $k$ independent hash functions each mapping an element to one of the $m$ positions.

**Insert $x$:** compute $h_1(x), \dots, h_k(x)$ and set all $k$ bits to 1.

**Query $x$:** compute the same $k$ positions.
- If **any** bit is 0 → $x$ was definitely never inserted. *(No false negatives: insertion only ever sets bits.)*
- If **all** bits are 1 → $x$ is *probably* present. The bits may have been set by other elements — a **false positive**.

```text
m = 16, k = 3

insert "cat"  -> positions 2, 7, 11
insert "dog"  -> positions 4, 7, 14

bits: 0 0 1 0 1 0 0 1 0 0 0 1 0 0 1 0
          ^   ^     ^     ^     ^

query "cow"   -> positions 2, 4, 11 -> all set -> FALSE POSITIVE
query "fish"  -> positions 1, 5, 9  -> bit 1 is 0 -> definitely absent
```

## Sizing It

With $n$ elements, $m$ bits, and $k$ hash functions, the false-positive probability is approximately

$$
p \approx \left(1 - e^{-kn/m}\right)^{k}
$$

Two formulas follow, and they are the ones to remember:

$$
k_{\text{opt}} = \frac{m}{n}\ln 2 \qquad\qquad m = -\frac{n \ln p}{(\ln 2)^2}
$$

The optimal $k$ is the one that leaves the bit array **half full** — more hash functions set more bits per insert, fewer leave more collisions, and the optimum balances the two.

| Target false-positive rate | Bits per element | Optimal $k$ |
| --- | --- | --- |
| 10% | ~4.8 | 3 |
| 1% | ~9.6 | 7 |
| 0.1% | ~14.4 | 10 |
| 0.01% | ~19.2 | 13 |

Each additional factor-of-10 reduction in $p$ costs about **4.8 more bits per element** — the growth is logarithmic, which is why very low error rates remain affordable. Note that the cost is independent of the element size: filtering a set of 200-byte URLs costs the same 10 bits each.

## Properties and Limits

| Property | Bloom filter |
| --- | --- |
| False negatives | Impossible |
| False positives | Possible, at a rate you choose in advance |
| Deletion | **Not supported** — clearing bits would break other elements |
| Enumeration | Impossible; you cannot read the set back out |
| Counting | Not supported |
| Resizing | Not supported; $n$ must be estimated up front |
| Union | Bitwise OR of two filters with identical $m$, $k$, and hash functions |
| Insert / query cost | $O(k)$, independent of $n$ |

> [!warning] The two things people get wrong
> A Bloom filter cannot tell you *what* is in the set, only whether something might be — and you must size it for the number of elements you will eventually hold, because there is no clean way to grow it.

## Variants

- **Counting Bloom filter** — replaces each bit with a small counter (typically 4 bits), so deletion becomes decrement. Costs 4× the space and can still overflow.
- **Scalable Bloom filter** — a chain of filters with geometrically tightening error rates; a new filter is added when the current one fills, which removes the fixed-$n$ requirement at the cost of querying every filter in the chain.
- **Cuckoo filter** — stores short fingerprints in a cuckoo hash table. Supports deletion, has better lookup locality, and beats a Bloom filter on space for false-positive rates below roughly 3%.
- **Quotient filter** — cache-friendly and mergeable, used where filters must be resized or merged on disk.
- **Count-Min sketch** — a relative, not a variant: it estimates *frequencies* rather than membership, using the same hash-into-an-array idea.

## Where It Is Used

- **LSM-tree storage engines** (RocksDB, LevelDB, Cassandra, HBase): one filter per SSTable, so a lookup skips files that cannot contain the key. Without this, a point read would have to touch every level.
- **Caches and CDNs:** "have we ever seen this object?" before paying for an origin fetch; some caches only admit an object on its second request, tracked by a filter.
- **Deduplication:** discard already-seen records in a stream or crawler frontier without keeping every ID in memory.
- **Databases:** join filtering — build a filter on the small side of a hash join and push it down to prune the large side before it is scanned.
- **Networking and security:** membership tests for blocklists where a false positive triggers a cheap authoritative check.

The pattern is always the same: **a false positive must be recoverable and merely cost a little work, never produce a wrong answer.** If a false positive would corrupt the result, a Bloom filter is the wrong tool.

## Related Concepts

- [[concepts/lsm_tree|Log-Structured Merge-Tree (LSM Tree)]] — the structure that depends on Bloom filters to keep read amplification manageable
- [[concepts/data_structures_algorithms|Data Structures and Algorithms]] — where approximate membership fits among the exact structures
- [[concepts/b_plus_tree|B+ Tree]] — the exact alternative; it answers membership precisely but must be traversed to do so
- [[concepts/data_quality|Data Quality]] — deduplication built on probabilistic membership trades a known error rate for scale, which is a data-quality decision, not just an engineering one

## References

- Burton H. Bloom — *Space/Time Trade-offs in Hash Coding with Allowable Errors* (1970)
- Broder, Mitzenmacher — *Network Applications of Bloom Filters: A Survey* (2004)
- Fan et al. — [Cuckoo Filter: Practically Better Than Bloom](https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf) (2014)
