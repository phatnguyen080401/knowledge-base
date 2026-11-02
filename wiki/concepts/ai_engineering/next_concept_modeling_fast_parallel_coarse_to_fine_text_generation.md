---
title: Next-Concept Modeling (NCM)
tags: [ai-engineering, generative-models, parallel-decoding, vector-quantization, scaling-laws]
sources: [raw/processed/next-concept_modeling_fast_parallel_coarse-to-fine_text_generation.pdf, "https://arxiv.org/pdf/2610.14162"]
created: 2026-11-02 14:22:13
updated: 2026-11-02 14:22:13
---

# Next-Concept Modeling (NCM)

Next-Concept Modeling is a two-stage, coarse-to-fine way to generate text in parallel. A multiscale
[[concepts/ai_engineering/residual_vector_quantization|Residual Vector Quantization (RVQ)]] tokenizer
encodes a sequence into $K$ levels of discrete codes, short and coarse at the top and full-length at
the bottom, and a transformer generates one level per step, predicting every code within a level at
once. Kumbong, Khare, et al. (Stanford and Together AI, October 2026) introduced it as a faster
alternative to the [[concepts/ai_engineering/diffusion_language_model|Diffusion Language Model (DLM)]],
the leading non-autoregressive approach. *Concept* here means the information the coarse levels
carry, not a semantic unit such as a sentence embedding.

## Why It Matters

- **Parallel without many steps.** A 128-token LM1B sample takes 12 generator calls, against the 128
  the strongest diffusion baseline uses, at better generative perplexity and matching diversity.
- **Cheap early steps.** Coarse levels hold few codes (level 1 holds one), so the first steps process
  far fewer positions than a diffusion step, which always processes the full length $L$.
- **No distillation stage.** Few-step diffusion samplers are usually distilled from a many-step
  teacher, which adds training and tends to cut sample diversity. NCM is few-step by construction.
- **Smaller training budget.** The tokenizer and generator together saw about 4–5× fewer training
  tokens than diffusion baselines on LM1B and OpenWebText.
- **Global revision.** Each level refines a representation of the whole output, so later levels can
  correct earlier ones. Left-to-right decoding cannot, which is why NCM beats autoregressive models
  on Sudoku.

## Three Generation Paradigms

![[raw/assets/next_concept_modeling_generation_paradigms.png|600]]

Next-token prediction takes $L$ steps of one token; masked diffusion takes $T$ steps that each
revisit all $L$ positions; NCM takes $K \ll L$ steps, where step $k$ predicts the $\ell_k$ codes
$r_k^1, \dots, r_k^{\ell_k}$ of level $k$, then decodes the final reconstruction into tokens.

| Paradigm | Sequential steps | Positions computed per step | Attention |
| --- | --- | --- | --- |
| Next-token prediction | $L$ | One new token; earlier ones come from the KV cache | Causal |
| Masked diffusion | $T$ | All $L$ | Bidirectional over the full sequence |
| NCM | $K$ (8–32 in the paper) | $\ell_k$, growing from 1 to $L$ | Within the current level |

## How It Works

> [!important] Two sources of speed
> NCM is faster because it makes fewer generator calls ($K$ levels instead of $T$ denoising steps)
> *and* because each call is cheaper: the early levels hold only a handful of codes.

### Stage 1: a multiscale residual tokenizer

A VQ-VAE maps the $L$ input tokens to $L$ latent vectors, then quantizes them in $K$ levels. Level
$k$ downsamples the residual left by the earlier levels to $\ell_k$ vectors, replaces each with its
nearest entry in that level's codebook, and adds the upsampled result to the cumulative
reconstruction $\hat z^{(k)}$, with $\ell_1 < \ell_2 < \dots < \ell_K = L$. The decoder maps any
reconstruction back to token distributions. **Nested dropout** during training keeps only the first
$k$ levels for a random $k$, which forces the early levels to carry meaningful content. The tokenizer
is then frozen. The mechanics and losses are in the RVQ note.

### Stage 2: a coarse-to-fine generator

The generator factorizes the hierarchy level by level and treats the codes within a level as
independent given the earlier levels:

$$p_\theta(r_{1:K}) = \prod_{k=1}^{K} p_\theta\left(r_k \mid \hat z^{(k-1)}\right), \qquad p_\theta\left(r_k \mid \hat z^{(k-1)}\right) = \prod_{i=1}^{\ell_k} p_\theta\left(r_k^i \mid \hat z^{(k-1)}\right)$$

That within-level independence is what lets one forward pass emit a whole level. Generation runs:

1. Start from an empty reconstruction, $\hat z^{(0)} = 0$.
2. For each level $k$: resize $\hat z^{(k-1)}$ to $\ell_k$ positions, project it to the hidden width,
   predict code distributions in one forward pass, sample all $\ell_k$ codes in parallel, and add
   their codebook vectors to the reconstruction.
3. Decode $\hat z^{(K)}$ with the tokenizer's decoder and take the argmax token at each position.

Training is not sequential. With the ground-truth codes known, all $K$ levels are predicted in **one
forward pass** under **block-diagonal attention**: each level's block attends only to itself, because
its input, the resized reconstruction of the earlier levels, already summarizes them. The loss is a
weighted cross-entropy over every code, where $\alpha = 0$ weights all codes equally and
$\alpha = 1$ weights all levels equally:

$$\mathcal{L}_{\text{NCM}} = -\sum_{k=1}^{K} w_k \sum_{i=1}^{\ell_k} \log p_\theta\left(r_k^i \mid \tilde z^{(k-1)}\right), \qquad w_k = \frac{\ell_k^{-\alpha}}{\sum_{j=1}^{K} \ell_j^{1-\alpha}}$$

![[raw/assets/next_concept_modeling_two_stage_training.png|600]]

(a) The tokenizer learns to encode text into codes $r_1, \dots, r_K$ and reconstruct it. (b) Those
codes become targets for the Next-Concept Transformer, which reads each level's cumulative
reconstruction of the earlier levels under block-diagonal attention.

### Conditioning corruption

Training conditions on clean ground-truth codes; generation conditions on the model's own samples.
Because a whole level is sampled at once, several wrong codes can enter the reconstruction together
and compound. NCM therefore trains with a fraction of the conditioning codes replaced by random codes
from the same level's codebook, at a rate that falls linearly across levels, while the targets stay
clean. The tilde in $\tilde z^{(k-1)}$ above marks that corrupted reconstruction.

### Conditional generation

Prompted tasks use a **prefix-LM** attention pattern. Prompt tokens are embedded with the frozen
tokenizer's token-embedding table and attend to each other; each target level attends to the prompt
and to itself; the prompt never attends to the targets. For XSum and WMT14 the generator was trained
first on unpaired text, then on source–target pairs.

## What the Levels Encode

![[raw/assets/next_concept_modeling_generation_trajectory.png|600]]

One German–English translation decoded after selected steps: step 1 fixes the opening ("However, it
is a…"), the middle steps assemble the content words amid heavy repetition, and step 11 produces the
final sentence (BLEU 77.8). Green marks words that match the reference.

Probes on the 12-level TinyStories model support the reading that coarse levels carry global
structure and fine levels carry detail:

- **Fixing the first three levels** and resampling the other nine kept each story's theme (a cold
  girl and a garment that moves; a boy alarmed by something in the sky) while changing 42–54% of the
  words: names, objects, and phrasing.
- **Mixing the coarse codes** of two stories produced text that blends both plots.
- **Replacing two level-1 codes** changed characters, objects, and events while preserving parts of
  the narrative.

Intermediate quality is not monotonic. In the translation above, per-level BLEU rose from 6.0 to
51.7 at level 8, fell to 38.9 at level 9, and ended at 77.8.

## Results

Generators are about 100M parameters (25M for Sudoku). Timings are end to end on one H100 SXM 80GB,
generating 1,024 sequences at batch size 16. NFE is the number of generator calls per output.

![[raw/assets/next_concept_modeling_efficiency_results.png|600]]

(a) On LM1B, NCM reaches lower generative perplexity than every diffusion baseline in 21× less
wall-clock time than the strongest, DUO. (b) On XSum it matches the best ROUGE-L 31× faster. (c) On
Sudoku it solves the most boards at every difficulty.

| Task | Metric | NCM (NFE) | Strongest non-AR baseline (NFE) |
| --- | --- | --- | --- |
| TinyStories, unconditional | Gen. PPL ↓ (entropy H) | 15.41 (3.98) at 12 | FMLM+ 15.43 (3.90) at 128 |
| LM1B, unconditional | Gen. PPL ↓ (entropy H) | 93.05 (4.31) at 12 | DUO 97.30 (4.30) at 128 |
| OpenWebText, unconditional | Gen. PPL ↓ (entropy H) | 83.12 (5.42) at 32 | DUO 77.69 (5.55) at 1,024 |
| XSum, no guidance | ROUGE-1 / 2 / L ↑ | 35.0 / 12.8 / 28.0 at 8 | AURORA-LM 34.7 / 12.2 / 26.6 at 128 |
| XSum, guidance or MBR | ROUGE-1 / 2 / L ↑ | 37.3 / 14.0 / 29.6 at 128 (MBR) | AURORA-LM + CFG 36.3 / 13.4 / 28.6 at 184 |
| WMT14 De–En, no guidance | BLEU ↑ | 22.6 at 11 | E2D2 24.8 at 64 |
| WMT14 De–En, guidance or MBR | BLEU ↑ | 25.2 at 132 (MBR) | ELF + CFG 26.4 at 128 |
| Sudoku easy / medium / hard | Boards solved ↑ | 99.5 / 96.5 / 86.1% at 12 | FMLM+ 97.7 / 92.8 / 81.3% at 16 |

Generative perplexity (Gen. PPL) is scored by GPT-2-large, and real text scores 9.67 (H 3.96) on
TinyStories, 53.51 (4.31) on LM1B, and 14.15 (5.44) on OpenWebText. Reading the table:

- NCM wins or ties on TinyStories, LM1B, XSum, and Sudoku with fewer calls: about 11× fewer on
  TinyStories and LM1B, 16× on unguided XSum, and 12 against 16 on Sudoku.
- On OpenWebText it trails DUO's Gen. PPL but runs 10× faster.
- On translation it trails E2D2 unguided and ELF with guidance; with MBR it ties the 99M
  autoregressive baseline (25.2 BLEU).
- Under four other scorers (Mistral-7B, Llama-3.1-8B, Gemma-2-9B, Qwen-3-14B), NCM still had the
  lowest average LM1B Gen. PPL (83.24 against DUO's 92.52), so that result does not hinge on GPT-2-large.

**Training budget.** On LM1B the tokenizer and generator together processed 13.36B token positions
(6.80B + 6.55B) against the baselines' 66B, 4.9× fewer. On OpenWebText they processed about 127B
against the 500B-plus of MDLM and DUO, about 4× fewer. The counts include padding and repeated passes
and measure token exposure, not FLOPs. The authors offer one untested explanation: a single fixed
coarse-to-fine order may be easier to learn than the many generation orders a diffusion model learns.

**Model scaling.** Generators of 97M, 317M, and 725M parameters on LM1B, sharing one frozen tokenizer,
improved Gen. PPL at a fixed training-token budget while keeping entropy high.

### Reasoning: Sudoku

![[raw/assets/next_concept_modeling_sudoku_trajectory.png|600]]

A hard puzzle (30 clues) decoded after each of the 12 steps. Level sizes grow from 1 to 89 codes,
correct cells climb from 16 of 81 to 81 of 81, and later levels overwrite wrong digits left by
earlier ones.

Every cell must satisfy its row, column, and box constraints at once, which punishes committing left
to right: the 25M autoregressive baseline solved only 14.6%, 5.1%, and 1.0% of easy, medium, and hard
boards. The Sudoku tokenizer reconstructs boards exactly (100%), and the generator refines the whole
board at every level.

## Test-Time Scaling with MBR Decoding

Because a sample costs few calls, NCM can spend one diffusion sample's budget on many samples.
**Minimum Bayes risk (MBR) decoding** draws $n$ candidates and keeps the one with the highest average
similarity to the others. Quality rose monotonically with diminishing returns, gaining 4.48 ROUGE-1
on XSum from 1 to 256 candidates. The reported settings use 16 candidates on XSum (128 NFE) and 12 on
WMT14 (132 NFE), and at matched wall-clock time NCM beats the diffusion baselines on XSum. Majority
voting in [[concepts/ai_engineering/chain_of_thought#Self-Consistency|self-consistency]] is the
exact-match special case of the same selection rule.

**Classifier-free guidance (CFG)** combines conditional and unconditional logits at each level with a
weight $w$, following VAR, and costs two calls per step. It helped translation more than
summarization: ROUGE peaked at $w = 0.5$ and BLEU at $w = 1.0$.

## Design Choices

Ablations ran on TinyStories unless noted, changing one choice at a time.

| Choice | Options tried | Finding |
| --- | --- | --- |
| Number of levels $K$ | 4, 8, 16, 32 | More levels lower Gen. PPL with diminishing returns: each doubling cut it by 52%, 32%, then 20%. All four reconstruct at least 99.95% of tokens |
| Level schedule ($K = 12$, 1 to 128 codes) | Linear, quadratic, square-root, log, exponential, cosine | Exponential (57.7) and quadratic (59.6) best; square-root (196.7) and log (168.2) worst; cosine 77.8, linear 88.4 |
| Attention | Block-causal, two-level sliding window, block-diagonal | Block-diagonal best and fastest: Gen. PPL 15.41 against 17.84 and 19.63; block-causal is 1.40× slower |
| Prompt encoder (XSum) | Frozen T5-small, or the tokenizer's own embeddings | T5 gains only 0.10–0.24 ROUGE for 35.3M extra parameters (about 40%), so NCM keeps its own |
| Loss weighting $\alpha$ | 0 to 1.5 | Raises the coarse levels' share of the loss from 19% to 63%, but Gen. PPL stays 18.9–19.0 for $\alpha \le 1$ and rises to 19.4 at 1.5 |
| Conditioning corruption | Mean rate 0 to 0.75 | Moderate rates improve quality greatly; excessive rates weaken the conditioning signal and hurt |

The two best schedules grow slowly at first and fast at the end; the two worst do the opposite.

![[raw/assets/next_concept_modeling_attention_patterns.png|600]]

Allowed query–key pairs over four levels for causal, block-causal, two-level sliding-window, and
NCM's block-diagonal attention, in which each level attends only within its own block.

## Probabilistic View

Treating the tokenizer's deterministic code assignment $r^*_{1:K}(x)$ as a point-mass variational
posterior gives an evidence lower bound (ELBO) on the text log-likelihood, made of a reconstruction
term and a generation term:

$$\log p_{\theta,\psi}(x) \ge \sum_{n=1}^{L} \log p_\psi\left(x_n \mid \hat z_*^{(K)}\right) + \sum_{k=1}^{K}\sum_{i=1}^{\ell_k} \log p_\theta\left(r_k^{*i} \mid \hat z_*^{(k-1)}\right)$$

The gap is exactly $-\log p_{\theta,\psi}(r^*_{1:K} \mid x)$, zero only when the posterior puts all
its mass on the tokenizer's hierarchy. With the tokenizer frozen, only the generation term depends on
$\theta$, so with clean conditioning and $\alpha = 0$ the NCM loss maximizes this bound. Corruption
and non-uniform weighting depart from it.

## Limitations

The authors list four:

- **Fixed schedule.** $K$ and every $\ell_k$ are fixed, so even a short continuation traverses the
  whole hierarchy; an input-dependent schedule would match compute to difficulty.
- **Separate tokenizer.** Representation learning is decoupled from the generative objective;
  end-to-end training might align them.
- **Small scale.** Main results are at about 100M parameters, and scaling was tested only to 725M on
  LM1B.
- **Transition artifacts.** Generations show occasional artifacts at coarse-level transitions.

The paper's setup adds further caveats:

- Each dataset gets its own tokenizer and generator, with a fixed target length $L$ from 48 to 1,024
  tokens.
- Tokenizer errors are rare but semantic. On OpenWebText 0.01% of tokens come back wrong, typically
  as swapped named entities or numerals, or as damaged diacritics, usernames, markup, or word
  boundaries.
- Several baseline scores are copied from other papers. Conditional baselines without released
  checkpoints were timed on randomly initialized models of the same architecture.
- The comparison targets diffusion models. Autoregressive sampling still scored better Gen. PPL where
  reported: 8.89 on TinyStories and 35.45 on OpenWebText.

## Related Approaches

| Approach | Relation to NCM |
| --- | --- |
| VAR next-scale prediction (Tian et al., 2024); HMAR (Kumbong et al., 2025) | The image method NCM ports to text: generate a multiscale code pyramid coarse to fine |
| RQ-VAE, SoundStream, EnCodec | Residual quantization in image and audio tokenizers |
| Latent diffusion for text, e.g. PLANNER | Also generates in a latent space, but continuous rather than in discrete levels |
| Block diffusion | Gets KV caching from sequential blocks, with parallelism only inside a block |
| MEGABYTE; H-Net | Hierarchies of byte patches or of learned dynamic chunks |
| Large Concept Models; ConceptLM; Dynamic Large Concept Models | Predict sentence representations or discrete concepts that guide token generation; ConceptLM's "next concept prediction" is a different method despite the similar name |
| HDLM | Refines tokens through a hierarchy of semantic vocabularies |

## Related Concepts

- [[concepts/ai_engineering/diffusion_language_model|Diffusion Language Model (DLM)]] — the baseline
  family NCM is designed to beat, and the source of its step-count and per-step-cost arguments
- [[concepts/ai_engineering/residual_vector_quantization|Residual Vector Quantization (RVQ)]] — the
  tokenizer mechanism that produces NCM's code hierarchy
- [[concepts/ai_engineering/chain_of_thought|Chain-of-Thought (CoT) Prompting]] — its
  self-consistency vote is the exact-match case of the MBR selection NCM uses at test time
- [[concepts/ai_engineering/agi/artificial_general_intelligence|Artificial General Intelligence (AGI)]] —
  test-time compute as a second scaling axis, which MBR decoding exploits here

## References

- Kumbong, Khare, Mlauzi, Woen, Ding, Buchanan, Arora, Mirhoseini, and Ré (2026).
  [Next-Concept Modeling: Fast, Parallel Coarse-to-Fine Text Generation](https://arxiv.org/abs/2610.14162).
  arXiv 2610.14162. Code: [HazyResearch/ncm](https://github.com/HazyResearch/ncm).
- Tian et al. (2024). *Visual Autoregressive Modeling: Scalable Image Generation via Next-Scale
  Prediction.* NeurIPS.
- Bertsch et al. (2023). *It's MBR All the Way Down: Modern Generation Techniques Through the Lens of
  Minimum Bayes Risk.* Big Picture Workshop.
