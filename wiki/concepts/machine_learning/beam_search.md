---
title: Beam Search
tags: [machine-learning, generative-models, decoding-strategies, sequence-modeling]
created: 2026-11-06 15:49:01
updated: 2026-11-11 13:07:11
---

# Beam Search

Beam search is a heuristic search that expands a tree of partial solutions level by level while
keeping only the $B$ most promising ones, the *beam*. In machine learning its main use is decoding:
finding a high-probability output sequence from an autoregressive sequence model, such as an
[[concepts/machine_learning/long_short_term_memory|LSTM]] translation model, one token at a time.
Lowerre introduced it in the Harpy speech-recognition system in 1976.

## Why It Matters

- **Exact search is impossible.** With vocabulary size $V$ and length $T$ there are $V^T$ possible
  sequences, so the most probable one cannot be found by trying them all. Beam search caps the work
  at about $B \cdot V$ scored candidates per step.
- **Greedy decoding is short-sighted.** Picking the single best token at each step can commit to a
  word that rules out every good continuation. Beam search keeps alternatives alive long enough for
  a better full sequence to win.
- **The beam width is a dial.** Width 1 is greedy decoding; a wider beam explores more and costs
  more, giving a direct trade between quality and compute.

## The Algorithm

A sequence model gives $p(y_t \mid y_{<t}, x)$, and a sequence is scored by its summed
log-probability. Summing logs avoids the underflow of multiplying many small probabilities:

$$
\text{score}(y) = \sum_{t=1}^{T} \log p(y_t \mid y_{<t}, x)
$$

1. Start the beam with one hypothesis: the start token, score 0.
2. **Expand.** Extend every hypothesis in the beam by every vocabulary token, adding each token's
   log-probability to the score. This gives $B \times V$ candidates.
3. **Prune.** Keep the $B$ highest-scoring candidates as the new beam. A candidate that emits the
   end token (EOS) moves to a list of finished hypotheses instead.
4. **Stop** when the beam is empty, the maximum length is reached, or no live hypothesis can still
   beat the best finished one (*early stopping*).
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

Looking at the top $2B$ candidates keeps $B$ live hypotheses even when some candidates end in EOS.
Each step costs one model call per hypothesis plus $O(BV \log B)$ to select the top $B$, so a
sequence of length $T$ costs about $O(TBV)$. Real implementations batch the $B$ hypotheses into one
model call, keep a KV cache per beam, and use a partial top-$k$ selection instead of a full sort.

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

## Length Bias and Its Fixes

Every extra token adds a negative log-probability, so raw scores favour short outputs and the
search tends to stop early. Common fixes:

| Fix | Rule |
| --- | --- |
| Average log-probability | Divide the score by the length $\lvert Y \rvert$ |
| Length normalization | Divide by $\lvert Y \rvert^\alpha$: $\alpha = 0$ is no correction, $\alpha = 1$ the per-token average |
| Length penalty (Wu et al., 2016) | Divide by $\mathrm{lp}(Y) = \dfrac{(5 + \lvert Y \rvert)^\alpha}{(5 + 1)^\alpha}$, with $\alpha$ around 0.6 to 0.7 |
| Coverage penalty | For attention models, penalize outputs whose attention ignores parts of the input |
| Repetition blocking | Forbid any n-gram from appearing twice in a hypothesis, a blunt fix for loops in summarization |
| Length bounds | Forbid the end token before a set length, and cap the maximum, often relative to the input length |

## Choosing the Beam Width

| Beam width $B$ | Behaviour |
| --- | --- |
| 1 | Identical to greedy decoding |
| Small, roughly 4–10 | The usual range for translation and summarization; most of the gain over greedy |
| Large | Higher model score, but often **worse** output, and $B$ times the compute and KV-cache memory of greedy |
| Unbounded | Exact maximum a posteriori (MAP) search, intractable for real vocabularies |

> [!important] A higher model score is not a better output
> In machine translation, quality often falls once the beam grows past about 5 to 10 (Koehn and
> Knowles, 2017). Stahlberg and Byrne (2019) ran exact search and found the single most probable
> translation was the empty sequence for most sentences. Beam search's pruning therefore partly
> hides model errors that a perfect search would expose.

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

For stories and dialogue, maximizing probability yields generic, looping text, while human text is
less probable token by token than what beam search picks. Sampling methods such as top-$k$ and
nucleus (top-$p$) sampling produce more natural text (Holtzman et al., 2020), and most chat language
models use sampling, not beam search.

MBR decoding, which
[[concepts/ai_engineering/next_concept_modeling_fast_parallel_coarse_to_fine_text_generation#Test-Time Scaling with MBR Decoding|NCM uses at test time]],
and the self-consistency vote in
[[concepts/ai_engineering/chain_of_thought#Self-Consistency|chain-of-thought prompting]] both replace
"find the most probable sequence" with "sample several and pick the consensus". This is the opposite
bet from beam search.

## Limitations

- **Not exact.** A sequence that starts with a low-probability token is pruned, however good its
  continuation would have been.
- **Little diversity.** The $B$ hypotheses often differ in a word or two (see Variants).
- **Memory.** Each live hypothesis needs its own KV cache, so memory grows linearly with $B$.

## Variants

- **Diverse beam search** (Vijayakumar et al., 2016; 2018). Splits the beam into groups that
  penalize tokens other groups already chose, producing genuinely different candidates.
- **Constrained beam search.** Filters or forces hypotheses by rules, such as required words,
  terminology, or valid syntax.
- **Stochastic beam search.** Samples the beam instead of taking the top $B$, giving diverse samples
  without replacement.
- **Search over reasoning steps.** Tree of thoughts runs a breadth-first search that keeps the most
  promising partial solutions, a beam search over steps rather than tokens.

> [!tip] Library knobs
> Hugging Face `generate()` exposes the pieces above as `num_beams`, `length_penalty` (the exponent
> $\alpha$), `early_stopping`, `no_repeat_ngram_size`, `num_beam_groups` with `diversity_penalty`, and
> `num_return_sequences` to get the top $n$ finished beams.

## Where It Is Used

| Setting | Why beam search fits |
| --- | --- |
| Machine translation, summarization, speech recognition | There is a narrow set of correct outputs, so the most probable sequence is close to what is wanted |
| Image captioning | Short outputs with a clear reference |
| Constrained generation | Hypotheses can be filtered by rules, such as required words or valid syntax |
| Approximate nearest-neighbour search | HNSW's layer-0 search keeps a beam of the best `ef` candidates while walking its graph, as described in [[concepts/databases/vector_database#HNSW — Hierarchical Navigable Small World\|Vector Database]] |

## Related Concepts

- [[concepts/machine_learning/long_short_term_memory|Long Short-Term Memory (LSTM)]] — sequence-to-sequence LSTMs were decoded with beam search, and the length-penalty work came from that era
- [[concepts/ai_engineering/diffusion_language_model|Diffusion Language Model (DLM)]] — generates many tokens in parallel by denoising instead of searching left to right, so beam search does not apply directly
- [[concepts/ai_engineering/next_concept_modeling_fast_parallel_coarse_to_fine_text_generation|Next-Concept Modeling (NCM)]] — spends its decoding budget on MBR selection over many samples, the consensus alternative to beam search
- [[concepts/ai_engineering/chain_of_thought|Chain-of-Thought (CoT) Prompting]] — self-consistency and tree of thoughts apply multi-path decoding and beam-style search to reasoning
- [[concepts/databases/vector_database|Vector Database]] — HNSW graph search uses the same keep-the-best-$B$ idea for nearest neighbours, with `ef` as the beam width

## References

- Lowerre (1976). *The HARPY Speech Recognition System.* PhD thesis, Carnegie Mellon University.
- Sutskever, Vinyals, and Le (2014). *Sequence to Sequence Learning with Neural Networks.* NeurIPS.
- Wu et al. (2016). [Google's Neural Machine Translation System: Bridging the Gap between Human and Machine Translation](https://arxiv.org/abs/1609.08144).
- Vijayakumar et al. (2016). [Diverse Beam Search: Decoding Diverse Solutions from Neural Sequence Models](https://arxiv.org/abs/1610.02424).
- Koehn and Knowles (2017). [Six Challenges for Neural Machine Translation](https://arxiv.org/abs/1706.03872). Workshop on Neural Machine Translation.
- Vijayakumar et al. (2018). *Diverse Beam Search for Improved Description of Complex Scenes.* AAAI.
- Stahlberg and Byrne (2019). [On NMT Search Errors and Model Errors: Cat Got Your Tongue?](https://arxiv.org/abs/1908.10090). EMNLP.
- Holtzman et al. (2020). [The Curious Case of Neural Text Degeneration](https://arxiv.org/abs/1904.09751). ICLR.
- Meister, Cotterell, and Vieira (2020). [If Beam Search Is the Answer, What Was the Question?](https://arxiv.org/abs/2010.02650). EMNLP.
