---
title: Beam Search
tags: [ai-engineering, generative-models, decoding-strategies]
created: 2026-11-11 10:08:36
updated: 2026-11-11 10:08:36
---

# Beam Search

Beam search is a decoding strategy for autoregressive sequence models. At each step it keeps only the
$B$ highest-scoring partial sequences (the *beam*), extends each by every possible next token, and
prunes back to the best $B$. This approximates the most probable whole output without enumerating
every sequence. It is the left-to-right counterpart to the parallel generators in
[[concepts/ai_engineering/diffusion_language_model|Diffusion Language Models (DLMs)]].

## Why It Matters

- **Greedy decoding is short-sighted.** Picking the single most likely token at each step can lock in
  an early choice whose continuations are all unlikely. Beam search keeps alternatives alive long
  enough for a better full sequence to win.
- **Exhaustive search is impossible.** A vocabulary of $V$ tokens and outputs of length $T$ give
  $V^T$ candidates. Beam search caps the work at about $B \cdot V$ scored candidates per step.
- **It is the default for "one right answer" tasks.** Machine translation, speech recognition,
  summarization, and captioning have used it since the speech-recognition work in which it was
  introduced (Lowerre's Harpy system, 1976).
- **The same idea appears outside text.** HNSW's layer-0 search in a
  [[concepts/databases/vector_database#HNSW — Hierarchical Navigable Small World|vector database]]
  is a beam search over a graph, with the candidate-list size `ef` acting as the beam width.

## How It Works

A sequence $y = (y_1, \dots, y_T)$ given input $x$ is scored by its summed log-probability, which
avoids the numeric underflow of multiplying many small probabilities:

$$
\text{score}(y) = \sum_{t=1}^{T} \log p(y_t \mid y_{<t}, x)
$$

1. Start with one hypothesis: the begin-of-sequence token, score 0.
2. **Expand.** For each of the $B$ live hypotheses, run the model once and add every token's
   log-probability to the hypothesis score. This gives $B \cdot V$ candidates.
3. **Prune.** Keep the top $B$ candidates. A candidate ending in end-of-sequence (EOS) moves to a
   *finished* list instead of the beam.
4. **Stop** when the beam is empty, the length limit is hit, or no live hypothesis can still beat the
   best finished one (*early stopping*).
5. **Return** the finished hypothesis with the best length-normalized score (below).

```python
from typing import Callable, Sequence


def beam_search(
    step: Callable[[tuple[int, ...]], Sequence[float]],  # prefix -> log-probs over the vocabulary
    bos: int,
    eos: int,
    beam_width: int,
    max_len: int,
    alpha: float = 1.0,
) -> tuple[int, ...]:
    beams = [((bos,), 0.0)]  # (prefix, summed log-probability)
    finished = []
    for _ in range(max_len):
        candidates = [
            (prefix + (token,), score + logp)
            for prefix, score in beams
            for token, logp in enumerate(step(prefix))
        ]
        candidates.sort(key=lambda c: c[1], reverse=True)
        beams = []
        for prefix, score in candidates[: 2 * beam_width]:
            if prefix[-1] == eos:
                finished.append((prefix, score))
            elif len(beams) < beam_width:
                beams.append((prefix, score))
        if not beams:
            break
    finished.extend(beams)  # hypotheses still open at max_len
    return max(finished, key=lambda c: c[1] / (len(c[0]) - 1) ** alpha)[0]
```

Looking at the top $2B$ candidates ensures $B$ live hypotheses survive even when some candidates end
in EOS. Production implementations batch the $B$ hypotheses into one forward pass and keep a separate
KV cache per beam.

> [!example]- Worked example: beam width 2 finds what greedy misses
> Vocabulary {A, B, C}. Step 1 gives A 0.5, B 0.4, C 0.1, so greedy commits to A.
>
> | Prefix | Next-token probabilities | Best two-token sequence |
> | --- | --- | --- |
> | A | A 0.4, B 0.3, C 0.3 | A A = 0.5 × 0.4 = 0.20 |
> | B | A 0.1, B 0.9 | B B = 0.4 × 0.9 = 0.36 |
>
> Greedy returns A A (0.20). With $B = 2$, both A and B survive step 1, and step 2 keeps B B (0.36)
> and A A (0.20), so beam search returns B B, the better sequence.

## Length Normalization and Penalties

Every added token adds a negative log-probability, so raw scores favour **short outputs**. Left
uncorrected, beam search prefers ending early. Common fixes:

- **Length normalization.** Divide the score by $|y|^\alpha$. $\alpha = 0$ applies no correction and
  $\alpha = 1$ is the per-token average. GNMT (Wu et al., 2016) used
  $\text{lp}(y) = \left(\tfrac{5 + |y|}{6}\right)^\alpha$, with $\alpha$ tuned on held-out data.
- **Coverage penalty.** In attention-based translation, penalize hypotheses that leave source words
  unattended, which reduces dropped content (also GNMT).
- **Repetition blocking.** Forbid any n-gram from appearing twice in a hypothesis, a blunt but
  effective fix for loops in summarization.
- **Length bounds.** Hard minimum and maximum lengths, often tied to the input length.

## Choosing the Beam Width

| Beam width $B$ | Behaviour |
| --- | --- |
| 1 | Identical to greedy decoding |
| Small, roughly 4–10 | The usual range for translation and summarization; most of the gain over greedy |
| Large | Higher model score, but often **worse** output, and $B$ times the compute and KV-cache memory of greedy |
| Unbounded | Exact maximum a posteriori (MAP) search, which is intractable for real vocabularies |

> [!important] A higher model score is not a better output
> Koehn and Knowles (2017) found translation quality *drops* as the beam grows past a small width.
> Stahlberg and Byrne (2019) ran exact search and found the single most probable translation was the
> empty sequence for most sentences. Beam search's pruning is therefore partly a feature: it hides
> model errors that a perfect search would expose.

Meister et al. (2020) explain this as an inductive bias: beam search favours text that spreads
information evenly across tokens, which humans also prefer. Their explanation is that beam search
works because it is an inexact search, not in spite of it.

## Beam Search vs. Other Decoding Strategies

| Strategy | Picks | Strengths | Weaknesses |
| --- | --- | --- | --- |
| Greedy | The argmax token each step | Cheapest, deterministic | Short-sighted; repetitive in long outputs |
| Beam search | The best of $B$ tracked sequences | Higher-likelihood outputs; strong on translation, ASR, summarization | $B$× cost; bland and repetitive in open-ended text; beams collapse to near-identical prefixes |
| Sampling (temperature, top-k, top-p) | A random draw from a truncated distribution | Diverse, human-like open-ended text | Non-deterministic; can drift off-topic |
| MBR decoding | The sample most similar to the other samples | Optimizes expected quality rather than probability | $n$ samples plus $n^2$ comparisons |
| Parallel decoding | Many positions per model call | Fewer sequential steps | Different model family, quality trade-offs |

For open-ended generation, Holtzman et al. (2020) showed that beam-search text is generic and loops,
while human text is less probable token by token than what beam search picks. This motivated nucleus
(top-p) sampling. Most hosted chat models expose sampling controls (temperature, top-p) rather than a
beam width.

MBR decoding, which
[[concepts/ai_engineering/next_concept_modeling_fast_parallel_coarse_to_fine_text_generation#Test-Time Scaling with MBR Decoding|NCM uses at test time]],
and the self-consistency vote in
[[concepts/ai_engineering/chain_of_thought#Self-Consistency|chain-of-thought prompting]] both replace
"find the most probable sequence" with "sample several and pick the consensus". This is the opposite
bet from beam search.

## Variants

- **Diverse beam search** (Vijayakumar et al., 2016). Splits the beam into groups and penalizes
  tokens other groups already chose, producing genuinely different candidates.
- **Constrained beam search.** Forces given words or phrases to appear, for terminology in
  translation or required keywords.
- **Stochastic beam search.** Samples the beam instead of taking the top $B$, giving diverse samples
  without replacement.
- **Search over reasoning steps.** Tree of thoughts runs a breadth-first search that keeps the most
  promising partial solutions, a beam search over steps rather than tokens.

> [!tip] Library knobs
> Hugging Face `generate()` exposes the pieces above as `num_beams`, `length_penalty` (the exponent
> $\alpha$), `early_stopping`, `no_repeat_ngram_size`, `num_beam_groups` with `diversity_penalty`, and
> `num_return_sequences` to get the top $n$ finished beams.

## Related Concepts

- [[concepts/ai_engineering/diffusion_language_model|Diffusion Language Model (DLM)]] — generates
  many positions per call instead of decoding left to right, so beam search does not apply directly
- [[concepts/ai_engineering/next_concept_modeling_fast_parallel_coarse_to_fine_text_generation|Next-Concept Modeling (NCM)]] —
  spends its decoding budget on MBR selection over many samples, the consensus alternative to beam
  search
- [[concepts/ai_engineering/chain_of_thought|Chain-of-Thought (CoT) Prompting]] — self-consistency
  and tree of thoughts apply multi-path decoding and beam-style search to reasoning
- [[concepts/databases/vector_database|Vector Database]] — HNSW graph search is a beam search with
  `ef` as the beam width

## References

- Lowerre, B. (1976). *The Harpy Speech Recognition System.* PhD thesis, Carnegie Mellon University.
- Wu et al. (2016). [Google's Neural Machine Translation System](https://arxiv.org/abs/1609.08144).
- Vijayakumar et al. (2016). [Diverse Beam Search](https://arxiv.org/abs/1610.02424).
- Koehn, P. and Knowles, R. (2017). [Six Challenges for Neural Machine Translation](https://arxiv.org/abs/1706.03872).
- Stahlberg, F. and Byrne, B. (2019). [On NMT Search Errors and Model Errors: Cat Got Your Tongue?](https://arxiv.org/abs/1908.10090). EMNLP.
- Holtzman et al. (2020). [The Curious Case of Neural Text Degeneration](https://arxiv.org/abs/1904.09751). ICLR.
- Meister, C., Cotterell, R., and Vieira, T. (2020). [If Beam Search Is the Answer, What Was the Question?](https://arxiv.org/abs/2010.02650). EMNLP.
