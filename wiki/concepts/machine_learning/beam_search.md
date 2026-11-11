---
title: Beam Search
tags: [machine-learning, generative-models, sequence-modeling]
created: 2026-11-06 15:49:01
updated: 2026-11-06 15:49:01
---

# Beam Search

Beam search is a heuristic search that expands a tree of partial solutions level by level while
keeping only the $B$ most promising ones, the *beam*. In machine learning its main use is decoding:
finding a high-probability output sequence from a sequence model, such as an
[[concepts/machine_learning/long_short_term_memory|LSTM]] translation model, one token at a time.
Lowerre introduced it in the Harpy speech-recognition system in 1976.

## Why It Matters

- **Exact search is impossible.** With vocabulary size $V$ and length $T$ there are $V^T$ possible
  sequences, so the most probable one cannot be found by trying them all.
- **Greedy decoding is short-sighted.** Picking the single best token at each step can commit to a
  word that rules out every good continuation.
- **The beam width is a dial.** Width 1 is greedy decoding; a wider beam explores more and costs
  more, giving a direct trade between quality and compute.

## The Algorithm

A sequence model gives $p(y_t \mid y_{<t}, x)$, and the score of a partial sequence is its
log-probability $\sum_t \log p(y_t \mid y_{<t}, x)$. Summing logs avoids underflow from multiplying
many small probabilities.

1. Start the beam with one hypothesis: the start token, score 0.
2. Extend every hypothesis in the beam by every vocabulary token, adding each token's
   log-probability to the score. This gives $B \times V$ candidates.
3. Keep the $B$ highest-scoring candidates as the new beam.
4. Move a hypothesis that emits the end token to a list of finished hypotheses.
5. Stop at the maximum length or when the best finished score cannot be beaten; return the best
   finished hypothesis.

```python
import math

def beam_search(step_log_probs, start, end, beam_width=4, max_len=50):
    """step_log_probs(prefix) -> {token: log_prob} for the next token."""
    beam = [([start], 0.0)]
    finished = []
    for _ in range(max_len):
        candidates = []
        for prefix, score in beam:
            for token, lp in step_log_probs(prefix).items():
                candidates.append((prefix + [token], score + lp))
        candidates.sort(key=lambda c: c[1], reverse=True)
        beam = []
        for seq, score in candidates[:beam_width]:
            (finished if seq[-1] == end else beam).append((seq, score))
        if not beam:
            break
    pool = finished or beam
    return max(pool, key=lambda c: c[1] / len(c[0]))   # length-normalized choice
```

Each step costs one model call per hypothesis plus $O(BV \log B)$ to select the top $B$, so a
sequence of length $T$ costs about $O(TBV)$. Real implementations batch the $B$ hypotheses into one
model call and use a partial top-$k$ selection instead of a full sort.

## Length Bias and Its Fixes

Every extra token adds a negative log-probability, so raw scores favour short outputs and the
search tends to stop early. Common fixes:

| Fix | Rule |
| --- | --- |
| Average log-probability | Divide the score by the length $\lvert Y \rvert$ |
| Length penalty (Wu et al., 2016) | Divide by $\mathrm{lp}(Y) = \dfrac{(5 + \lvert Y \rvert)^\alpha}{(5 + 1)^\alpha}$, with $\alpha$ around 0.6 to 0.7 |
| Coverage penalty | For attention models, penalize outputs whose attention ignores parts of the input |
| Minimum length | Forbid the end token before a set length |

## Limitations

- **Not exact.** A sequence that starts with a low-probability token is pruned, however good its
  continuation would have been.
- **Wider is not always better.** In machine translation, quality often falls once the beam grows
  past about 5 to 10, because the model's most probable outputs are short or empty (Koehn and
  Knowles, 2017; Stahlberg and Byrne, 2019).
- **Bland and repetitive open-ended text.** For stories and dialogue, maximizing probability yields
  generic, looping text. Sampling methods such as top-$k$ and nucleus (top-$p$) sampling produce more
  natural text (Holtzman et al., 2020), and most chat language models use sampling, not beam search.
- **Little diversity.** The $B$ hypotheses often differ in a word or two. Diverse beam search
  (Vijayakumar et al., 2018) splits the beam into groups that penalize similarity.

## Where It Is Used

| Setting | Why beam search fits |
| --- | --- |
| Machine translation, summarization, speech recognition | There is a narrow set of correct outputs, so the most probable sequence is close to what is wanted |
| Image captioning | Short outputs with a clear reference |
| Constrained generation | Hypotheses can be filtered by rules, such as required words or valid syntax |
| Approximate nearest-neighbour search | HNSW keeps a beam of the best candidates while walking its graph, as described in [[concepts/databases/vector_database\|Vector Database]] |

## Related Concepts

- [[concepts/machine_learning/long_short_term_memory|Long Short-Term Memory (LSTM)]] — sequence-to-sequence LSTMs were decoded with beam search, and the length-penalty work came from that era
- [[concepts/ai_engineering/diffusion_language_model|Diffusion Language Model (DLM)]] — generates many tokens in parallel by denoising instead of searching left to right
- [[concepts/databases/vector_database|Vector Database]] — HNSW graph search uses the same keep-the-best-$B$ idea for nearest neighbours

## References

- Lowerre (1976). *The HARPY Speech Recognition System.* PhD thesis, Carnegie Mellon University.
- Sutskever, Vinyals, and Le (2014). *Sequence to Sequence Learning with Neural Networks.* NeurIPS.
- Wu et al. (2016). *Google's Neural Machine Translation System: Bridging the Gap between Human and Machine Translation.* arXiv:1609.08144.
- Koehn and Knowles (2017). *Six Challenges for Neural Machine Translation.* Workshop on Neural Machine Translation.
- Vijayakumar et al. (2018). *Diverse Beam Search for Improved Description of Complex Scenes.* AAAI.
- Stahlberg and Byrne (2019). *On NMT Search Errors and Model Errors: Cat Got Your Tongue?* EMNLP.
- Holtzman et al. (2020). *The Curious Case of Neural Text Degeneration.* ICLR.
