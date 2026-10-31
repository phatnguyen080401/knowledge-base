---
title: Retrieval Scoring and Ranking
tags: [ai-engineering, llm-applications, retrieval-augmentation]
created: 2026-10-31 11:07:29
updated: 2026-10-31 11:07:29
---

# Retrieval Scoring and Ranking

Retrieval scoring is how a search system assigns each candidate chunk a number for its relevance to a query, and ranking is how it turns those numbers into the short list passed to the model. In [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]], several scoring stages run in sequence, each on its own scale.

## Why It Matters

- **The ranking decides what the model sees.** Only the top few chunks reach the prompt, so a relevant chunk ranked eleventh when $k$ is ten might as well not exist.
- **Scores are not comparable across stages.** A cosine of 0.8 and a BM25 score of 12 mean nothing relative to each other, and mixing them naively is a common bug.
- **Selection rules decide failure behaviour.** Whether the system can say "nothing relevant was found" depends on how it cuts the ranked list, not on the retriever.

## Scoring Stages

| Stage | Score | Scale | Notes |
| --- | --- | --- | --- |
| Dense retrieval | Cosine similarity or dot product between query and chunk embeddings | Per model; often compressed into a narrow band | See [[concepts/ai_engineering/embeddings#Measuring Closeness\|Measuring Closeness]] |
| Lexical retrieval | BM25 | Unbounded; depends on corpus and query length | Strong on exact terms, codes, and names |
| Fusion | Reciprocal rank fusion, from ranks only | Small positive numbers | Sidesteps the scale mismatch; see [[concepts/databases/vector_database#Hybrid Search\|Hybrid Search]] |
| Reranking | Cross-encoder relevance score for each query–chunk pair | Per model, often an unnormalized logit | The most accurate score and the slowest, so applied only to the top few dozen candidates |

Each stage narrows the list for the next, more expensive one: cheap retrieval over millions of chunks, fusion over a few hundred, reranking over a few dozen, and the prompt gets a handful.

## BM25

BM25 scores a chunk $D$ against query terms $q_i$ by rewarding rare terms that appear in it, with diminishing returns for repetition and a penalty for long chunks:

$$
\text{BM25}(D, Q) = \sum_{i} \text{IDF}(q_i) \cdot \frac{f(q_i, D)\,(k_1 + 1)}{f(q_i, D) + k_1 \left(1 - b + b \frac{|D|}{\text{avgdl}}\right)}
$$

- $f(q_i, D)$ is the term's frequency in the chunk, $|D|$ the chunk length, and avgdl the average chunk length in the corpus.
- **IDF** gives rare terms more weight than common ones.
- **$k_1$**, typically 1.2 to 2.0, controls how quickly repeated occurrences stop adding score.
- **$b$**, typically 0.75, controls how strongly long chunks are penalized.

Because of the length term, changing the chunk size changes BM25 scores even when the text is the same.

## Choosing What to Keep

| Rule | Behaviour | Risk |
| --- | --- | --- |
| **Top-$k$** | Always returns $k$ chunks | Passes irrelevant chunks to the model when nothing relevant exists |
| **Score threshold** | Returns only chunks above a cut-off | The cut-off must be calibrated per model, because similarity scores are not probabilities |
| **Top-$k$ with a minimum score** | Up to $k$ chunks, only those above the cut-off | The common compromise; lets the system answer "not found" |

Re-calibrate any threshold whenever the embedding or reranker model changes, since score distributions differ between models.

## Diversity with MMR

Ranking by score alone often returns near-duplicates, such as overlapping chunks or several copies of the same document. **Maximal marginal relevance (MMR)** picks each next chunk by trading relevance to the query against similarity to the chunks already chosen:

$$
\text{MMR} = \arg\max_{d \in R \setminus S} \Big[ \lambda \, \text{sim}(d, q) - (1 - \lambda) \max_{s \in S} \text{sim}(d, s) \Big]
$$

$R$ is the candidate set, $S$ the chunks selected so far, and $\lambda$ the balance: 1 means pure relevance, and lower values favour variety.

## Business Signals

Recency, source authority, or document type can be applied as boosts or filters after fusion or reranking. Mixing them into raw similarity scores breaks the per-stage calibration and makes the ranking hard to debug.

## Common Pitfalls

- **Adding raw scores from different retrievers.** BM25 and cosine live on unrelated scales. Use rank-based fusion, or normalize per query and tune the weights on labelled data.
- **Reading a similarity score as a probability.** A cosine of 0.82 is not "82% relevant".
- **Keeping a threshold across a model change.** Score distributions shift with every model.
- **Raising $k$ instead of fixing the ranking.** More chunks add distractors and cost, and precision usually falls faster than recall rises.

## Related Concepts

- [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]] — the pipeline whose retrieve and rerank stages these scores drive
- [[concepts/ai_engineering/embeddings|Embeddings]] — the similarity metrics behind dense scores, and the bi-encoder vs. cross-encoder split behind reranking
- [[concepts/databases/vector_database|Vector Database]] — where dense and hybrid retrieval run, including reciprocal rank fusion
- [[concepts/ai_engineering/chunk_overlap|Chunk Overlap]] — a source of near-duplicate candidates that diversity-aware selection has to handle
- [[concepts/ai_engineering/context_window|Context Window]] — the budget that limits how many ranked chunks can be passed on
