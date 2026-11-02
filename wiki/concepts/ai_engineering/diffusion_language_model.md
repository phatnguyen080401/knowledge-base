---
title: Diffusion Language Model (DLM)
tags: [ai-engineering, generative-models, parallel-decoding]
sources: [raw/processed/next-concept_modeling_fast_parallel_coarse-to-fine_text_generation.pdf, "https://arxiv.org/pdf/2610.14162"]
created: 2026-11-02 14:22:13
updated: 2026-11-02 14:22:13
---

# Diffusion Language Model (DLM)

A diffusion language model generates text by iterative denoising. It starts from a fully corrupted
sequence and refines every position over a series of steps, instead of emitting one token at a time
from left to right. DLMs are the leading non-autoregressive way to generate many tokens per model
call, and the baseline that
[[concepts/ai_engineering/next_concept_modeling_fast_parallel_coarse_to_fine_text_generation|Next-Concept Modeling (NCM)]]
sets out to beat.

## Why It Matters

- **Parallel sampling.** The promise is a sequence in far fewer sequential steps than it has tokens.
  That matters more as inference becomes one of the dominant computational workloads.
- **It is moving into production.** Open models such as LLaDA scale to billions of parameters;
  Mercury (Inception Labs) and DiffusionGemma serve diffusion models commercially; and DFlash uses a
  block-diffusion model as the drafter that speeds up an autoregressive model through speculative
  decoding.
- **The promise is only partly delivered.** Quality drops when steps are cut, each step is
  expensive, and training is costly (see [[concepts/ai_engineering/diffusion_language_model#Where DLMs Fall Short|Where DLMs Fall Short]]).

## How Masked Diffusion Works

Masked (absorbing-state) diffusion is the most common discrete form. It is described here from
general knowledge of the MDLM line of work.

- **Forward process.** Clean text is corrupted by replacing tokens independently with a `[MASK]`
  token, with a masking probability that rises from 0 to 1 over the noise schedule.
- **Reverse model.** A bidirectional transformer reads a partly masked sequence and predicts a
  distribution over the original token at every masked position.
- **Sampling.** Generation starts with all $L$ positions masked. Each of $T$ steps predicts the masked
  positions and unmasks a subset, until none remain.
- **Training.** In MDLM the objective reduces to a weighted average of masked-language-modeling
  cross-entropy losses across noise levels, which bounds the likelihood.

![[raw/assets/next_concept_modeling_generation_paradigms.png|600]]

Next-token prediction takes $L$ steps of one token. Masked diffusion takes $T$ steps, each revisiting
all $L$ positions, and fills masked slots (`?`) progressively. NCM, on the right, generates a short
coarse-to-fine hierarchy of codes instead.

## Families

The NCM paper benchmarks against most of these:

| Family | What is noised or generated | Examples |
| --- | --- | --- |
| Discrete, masked | Tokens replaced by a mask token | D3PM (absorbing variant), MDLM |
| Discrete, ratio-based | Token distributions, learned by estimating probability ratios | SEDD |
| Discrete, uniform-state | Tokens replaced by random tokens | DUO |
| Continuous | Token representations evolved in an embedding space | CDCD, ELF, AURORA-LM |
| Hybrid | Discrete and continuous noise together | CANDI |
| Flow map | A learned direct map between noise levels, for one or few steps | FLM, FMLM+ |
| Encoder–decoder | Diffusion decoder conditioned on an encoded source | E2D2, SeqDiffuSeq |
| Block (semi-autoregressive) | Diffusion inside a block, blocks generated left to right | Block Diffusion, Fast-dLLM v2 |

## Where DLMs Fall Short

The NCM authors, who propose a competing method, name three practical limits:

1. **Many sampling steps.** Tokens are predicted in parallel, but the denoising passes are still
   sequential, and cutting them degrades quality fast. That caps the speedup parallelism can buy.
2. **Expensive sampling steps.** Every step processes the full length-$L$ sequence. Bidirectional
   attention also prevents direct reuse of the autoregressive
   [[concepts/ai_engineering/context_window#Why the Window Is Finite|KV cache]].
3. **Large training budgets.** Training often makes many passes over the same data. MDLM and DUO
   were trained on OpenWebText for 1M steps, over 500B tokens; the LM1B baselines in the NCM paper
   ran 1M iterations over 66B tokens.

![[raw/assets/diffusion_language_model_quality_vs_nfe.png|600]]

Generative perplexity against the number of generator calls (NFE) on TinyStories and LM1B, and
against seconds per 1,024-token sequence on OpenWebText. Every diffusion baseline's perplexity climbs
steeply as the step count falls toward 8. NCM, the star, sits below the curves.

At 128 steps on LM1B the baselines score 97.30 (DUO), 112.33 (FLM), 115.45 (MDLM), and 124.64
(CANDI), against 53.51 for real text and 93.05 for NCM at 12 steps.

## Mitigations and Their Costs

| Technique | What it fixes | Cost, per the NCM paper |
| --- | --- | --- |
| Few-step distillation (DUO, SDTT) | Number of steps: a many-step teacher is distilled into a few-step student | An extra training stage on an already expensive model; students are less diverse; per-step cost unchanged |
| Flow maps (FLM, FMLM+) | Number of steps, by learning a direct map between noise levels | The same trade-offs. On OpenWebText, FLM and FMLM+ reach low perplexity at entropy below the data's, which partly reflects lost diversity |
| Block diffusion | Enables KV caching | Parallel only within a block; each block waits for the previous one |
| DLM-specific KV caches (Fast-dLLM, dKV-Cache) | Per-step cost | Cited but not evaluated in the source |
| Classifier-free guidance | Conditional quality | Two generator calls per step |

## Evaluating Parallel Generators

- **Generative perplexity (Gen. PPL).** The perplexity of generated samples under a reference
  autoregressive model, GPT-2-large by convention. Lower is better.
- **Unigram entropy (H).** Gen. PPL can be lowered by making samples less diverse, so mean per-sample
  unigram entropy is reported beside it and compared with real text (OpenWebText: Gen. PPL 14.15,
  H 5.44).
- **Reference-model dependence.** A robust comparison repeats the scoring under other reference
  models. The NCM paper used Mistral-7B, Llama-3.1-8B, Gemma-2-9B, and Qwen-3-14B.
- **NFE against wall-clock time.** NFE counts generator calls, with a guided step counting two. It
  ignores per-step cost, which differs between methods, so end-to-end time on fixed hardware and batch
  size is the fairer efficiency measure.
- **Task metrics.** BLEU for translation (WMT14), ROUGE-1/2/L for summarization (XSum), and the share
  of completely solved boards for Sudoku.

> [!warning] Low perplexity alone is not quality
> Always read Gen. PPL together with entropy. A sampler that collapses toward repetitive text scores
> well on perplexity; on OpenWebText, greedy autoregressive decoding reaches 1.07 at an entropy of 1.65.

## Related Concepts

- [[concepts/ai_engineering/next_concept_modeling_fast_parallel_coarse_to_fine_text_generation|Next-Concept Modeling (NCM)]] —
  a coarse-to-fine alternative that targets all three limits above
- [[concepts/ai_engineering/context_window|Context Window]] — the KV cache that makes autoregressive
  steps cheap, and that full-sequence diffusion cannot reuse directly
- [[concepts/ai_engineering/residual_vector_quantization|Residual Vector Quantization (RVQ)]] — the
  discrete-code route to parallel generation, in contrast to diffusion over tokens or embeddings

## References

- Austin et al. (2021). *Structured Denoising Diffusion Models in Discrete State-Spaces.* NeurIPS.
- Lou, Meng, and Ermon (2024). *Discrete Diffusion Modeling by Estimating the Ratios of the Data
  Distribution.* arXiv 2310.16834.
- Sahoo et al. (2024). *Simple and Effective Masked Diffusion Language Models.* arXiv 2406.07524.
- Sahoo et al. (2025). *The Diffusion Duality.* ICML.
- Arriola et al. (2025). *Block Diffusion: Interpolating Between Autoregressive and Diffusion Language
  Models.* ICLR.
- Nie et al. (2025). *Large Language Diffusion Models.* arXiv 2502.09992.
- Kumbong, Khare, et al. (2026). [Next-Concept Modeling: Fast, Parallel Coarse-to-Fine Text
  Generation](https://arxiv.org/abs/2610.14162). arXiv 2610.14162.
