---
title: Chunk Overlap
tags: [ai-engineering, llm-applications, retrieval-augmentation]
created: 2026-10-31 11:07:29
updated: 2026-10-31 11:07:29
---

# Chunk Overlap

Chunk overlap is the practice of repeating the end of each chunk at the start of the next when splitting documents for retrieval, so that a passage falling on a boundary still appears whole in at least one chunk. It is a parameter of the chunking stage in [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]], most often used with fixed-size and recursive chunking.

## Why It Matters

Chunk boundaries are usually placed by length, not by meaning. A fact that straddles a boundary is split in two, and each half may match a query poorly, so the passage that answers the question is never retrieved. Overlap is the cheapest defence against that, but it costs index size and creates duplicates downstream, so it should be set deliberately rather than left at a library default.

## How It Works

With chunk size $n$ and overlap $o$ tokens, the window advances by a **stride** of $n - o$. Any passage no longer than $o$ tokens lies entirely inside at least one chunk. With 512-token chunks and a 64-token overlap, the stride is 448:

| Chunk | Tokens |
| --- | --- |
| 1 | 0–511 |
| 2 | 448–959 |
| 3 | 896–1,407 |

For a document of $L$ tokens:

$$
\text{chunks} \approx \left\lceil \frac{L - o}{n - o} \right\rceil, \qquad \text{index growth} \approx \frac{n}{n - o}
$$

A 20% overlap stores and embeds about 1.25× the text, and a 50% overlap about 2×. Embedding cost, vector storage, and lexical index size all grow by the same factor.

## Choosing an Overlap

- **Start small and measure.** 10–20% of the chunk size is the usual starting point. Raise it only if recall@k on a labelled question set improves, since the cost grows faster than the benefit.
- **Overlap on boundaries.** Overlap whole sentences rather than a raw token count, so no chunk starts or ends mid-sentence.
- **Size it to the units that get split.** The overlap needs to be at least as long as the passages you need kept whole, such as a sentence, a definition, or a short step.

## When to Skip It

Overlap compensates for boundaries that ignore meaning. Where the boundaries already respect meaning, it adds cost without benefit:

- **Structure-aware chunks** split along headings, sections, or list items, which are mostly self-contained.
- **Parent–child and sentence-window retrieval** find a small unit, then expand to its surrounding context at query time, which does overlap's job without storing duplicates.
- **Propositional chunks** are rewritten to stand alone.

The RAG note's [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki#Chunking Strategies|Chunking Strategies]] table compares these strategies.

## Side Effects

- **Duplicates at retrieval.** Adjacent overlapping chunks often both rank highly, taking two of the top-$k$ slots and repeating text in the prompt. Merge adjacent hits into one passage, or deduplicate during context assembly.
- **Skewed scores.** Text in the overlap region exists twice in the index, so a query matching it can return two near-identical results. Diversity-aware selection such as maximal marginal relevance, described in [[concepts/ai_engineering/retrieval_scoring|Retrieval Scoring and Ranking]], counters this.
- **Overlap does not restore distant context.** If a chunk depends on something stated pages earlier, such as which company "it" refers to, overlap does not help. Prepending document-level context to each chunk, covered under [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki#Contextual Retrieval|Contextual Retrieval]], does.

## Related Concepts

- [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]] — the pipeline whose chunking stage overlap belongs to, with the full comparison of chunking strategies
- [[concepts/ai_engineering/retrieval_scoring|Retrieval Scoring and Ranking]] — how overlapping chunks are scored, and how MMR and deduplication keep them from crowding the results
- [[concepts/ai_engineering/embeddings|Embeddings]] — every extra chunk overlap creates is another vector to compute and store
- [[concepts/ai_engineering/context_window|Context Window]] — duplicated overlap text wastes the token budget the retrieved context must fit in
