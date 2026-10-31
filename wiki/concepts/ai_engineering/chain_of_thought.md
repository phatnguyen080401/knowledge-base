---
title: Chain-of-Thought (CoT) Prompting
tags: [ai-engineering, llm-applications, in-context-learning]
sources: ["https://arxiv.org/abs/2201.11903", "https://arxiv.org/abs/2205.11916", "https://arxiv.org/abs/2203.11171", "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices", "https://arxiv.org/abs/2205.10625", "https://arxiv.org/abs/2305.10601", "https://arxiv.org/abs/2211.10435", "https://arxiv.org/abs/2210.03493", "https://arxiv.org/abs/2305.04388", "https://arxiv.org/abs/2501.12948"]
created: 2026-10-30 10:57:29
updated: 2026-10-31 11:07:29
---

# Chain-of-Thought (CoT) Prompting

Chain-of-thought prompting is a [[concepts/ai_engineering/prompt_engineering|Prompt Engineering]]
technique that has a language model write out intermediate reasoning steps before its final
answer, rather than producing the answer directly. Spending generated tokens on the steps of a
problem improves accuracy on multi-step tasks such as arithmetic, symbolic manipulation, logic, and
planning, and the idea has since been built into models that reason before answering by default.

## Why It Matters

- **It buys accuracy with tokens, not training.** On maths word problems, adding reasoning steps to
  the prompt moved models from a minority of correct answers to state of the art with no change to
  the weights.
- **Each token is a fixed amount of computation.** Asking for the answer immediately gives the model
  one forward pass per answer token; writing the steps first lets it spend more computation on
  harder problems and condition each step on the previous ones.
- **It is the foundation of a family.** Self-consistency, least-to-most, tree of thoughts, and
  program-aided reasoning are all variations on "generate intermediate steps, then answer".
- **Reasoning models made it a default.** Current models trained to think before answering run a
  chain of thought internally, which changes how it should be prompted.

## How It Works

Treat the reasoning $r$ as a hidden intermediate between the question $q$ and the answer $a$. The
probability of an answer is then a sum over every reasoning path that leads to it:

$$p(a \mid q) = \sum_{r} p(r \mid q)\, p(a \mid q, r)$$

Standard prompting asks the model for $a$ directly. Chain-of-thought prompting samples or greedily
decodes one path $\hat r$ and reads the answer off its end, $\hat a = \arg\max_a p(a \mid q, \hat r)$.
That single path can be wrong even when most paths are right, which is the gap self-consistency
closes by sampling many paths and approximating the sum.

The canonical evidence, Wei et al. (2022): eight hand-written exemplars with worked reasoning took
a 540B-parameter model (PaLM) to state-of-the-art accuracy on the GSM8K maths benchmark, ahead of a
fine-tuned GPT-3 with a verifier. The authors describe the ability as emerging only in sufficiently
large models; small models produced fluent but illogical chains that did not help.

## Variants

### Few-Shot CoT

The demonstrations contain the reasoning, not just the answers, so the model imitates the format.

```text
Q: A shop has 23 apples. It uses 20 for lunch and buys 6 more. How many apples does it have?
A: It starts with 23 apples. After using 20 it has 23 - 20 = 3. Buying 6 more gives 3 + 6 = 9.
The answer is 9.

Q: <new question>
A:
```

Ending every exemplar with the same phrase ("The answer is …") makes the final answer easy to parse.

### Zero-Shot CoT

Kojima et al. (NeurIPS 2022) showed a trigger phrase is enough, with no exemplars. It runs in two
stages: one call to produce the reasoning, a second to extract the answer from it.

```text
Stage 1:  Q: <question>
          A: Let's think step by step.
Stage 2:  <question + the reasoning from stage 1>
          Therefore, the answer (arabic numerals) is
```

With `text-davinci-002`, this raised accuracy from 17.7% to 78.7% on MultiArith and from 10.4% to
40.7% on GSM8K, with similar gains on PaLM 540B.

### Auto-CoT

Writing good reasoning exemplars by hand is slow. Auto-CoT (Zhang et al., 2022) generates them: it
picks a diverse set of questions, produces a chain for each with zero-shot CoT, and uses those as
the few-shot demonstrations. Diversity matters because some generated chains are wrong; on ten
benchmarks with GPT-3 it matched or beat hand-written CoT exemplars.

### Self-Consistency

Wang et al. (ICLR 2023) replace the single greedy path with $m$ sampled paths
$(r_1, a_1), \dots, (r_m, a_m)$ at non-zero temperature, then take the answer most paths agree on:

$$\hat a = \arg\max_{a} \sum_{i=1}^{m} \mathbb{1}[a_i = a]$$

This is a Monte Carlo approximation of the marginal $p(a \mid q)$ above. Over plain CoT it gained
+17.9 points on GSM8K, +11.0 on SVAMP, +12.2 on AQuA, +6.4 on StrategyQA, and +3.9 on
ARC-challenge. It needs answers that can be compared for equality (a number, a label, a choice),
and it costs roughly $m$ times the tokens of a single chain.

### Least-to-Most

Zhou et al. (ICLR 2023) split the work into two stages: first **decompose** the problem into simpler
subproblems, then **solve them in order**, feeding each answer into the next. It targets problems
harder than any exemplar: on the SCAN compositional-generalisation benchmark, `code-davinci-002`
reached at least 99% accuracy on every split with 14 exemplars, where chain-of-thought reached 16%.

```text
Stage 1:  To solve "<problem>", we first need to solve: <subproblem 1>, <subproblem 2>, ...
Stage 2:  <problem> + Q: <subproblem 1>  A: ...  Q: <subproblem 2>  A: ...
```

### Tree of Thoughts

Yao et al. (NeurIPS 2023) turn the single left-to-right chain into a search. Each "thought" is a
coherent chunk of reasoning; the model proposes several next thoughts, evaluates them itself, and
a search algorithm (breadth- or depth-first) expands the promising ones and backtracks from dead
ends. On the Game of 24 puzzle, GPT-4 solved 4% of tasks with CoT and 74% with tree of thoughts,
at the price of many model calls per problem.

### Program-Aided Reasoning

In PAL (Gao et al., 2022) the model writes its reasoning as a program, and an interpreter runs it to
produce the answer. The model only has to decompose the problem; the interpreter does the
arithmetic, which removes the calculation errors that plague natural-language chains. With Codex on
GSM8K it beat PaLM 540B with chain-of-thought by 15 points (top-1).

```python
# Q: A shop has 23 apples. It uses 20 for lunch and buys 6 more. How many apples does it have?
apples = 23
apples -= 20
apples += 6
answer = apples
```

## Choosing a Variant

| Variant | Model calls | Needs | Best for |
| --- | --- | --- | --- |
| Zero-shot CoT | 1–2 | A trigger phrase | A quick baseline on any reasoning task |
| Few-shot CoT | 1 | Hand-written worked examples | A consistent reasoning format and parseable answers |
| Auto-CoT | 1, after a one-off build | A pool of unlabelled questions | Few-shot CoT without writing chains by hand |
| Self-consistency | $m$, often 5–40 | Answers comparable for equality | Accuracy-critical tasks with discrete answers |
| Least-to-most | 2 or more | Decomposition exemplars | Problems harder than the examples, compositional tasks |
| Tree of thoughts | Many | A way to score partial solutions | Search and puzzle tasks where early choices can be wrong |
| Program-aided | 1 plus execution | A sandboxed interpreter | Arithmetic and algorithmic problems |

The call counts for self-consistency are the typical range in practice, not a figure from the paper.

## Reasoning Models

Models trained to reason before answering produce long chains of thought by themselves. DeepSeek-R1
(published in *Nature*, 2025) showed that reinforcement learning on verifiable tasks alone, without
human-written reasoning traces, can produce this behaviour, including self-reflection,
verification, and changing strategy mid-problem.

That shifts the prompting advice. Anthropic's guidance for its models with thinking enabled:

- Prefer a general instruction such as "think thoroughly" over a prescriptive step-by-step plan; the
  model's own reasoning often exceeds what a human would write.
- Few-shot examples still help: worked examples shape how the model reasons about similar problems.
- Use manual CoT only as a fallback when thinking is off. On some current models, a prompt asking the
  model to write its reasoning in the visible answer may be declined; use the thinking mode, at a
  lower effort level if cost matters.

> [!tip] Separate the reasoning from the answer
> Whether the reasoning lives in a thinking mode or in the visible output, put the final answer in a
> fixed place, such as an `<answer>` tag or a closing "The answer is …" sentence, so code can extract
> it without parsing the reasoning.

## Faithfulness

A chain of thought is generated text, not a trace of the model's computation, and it can be wrong
about why the model answered as it did. Turpin et al. (NeurIPS 2023) biased few-shot prompts, for
example by always putting the correct option in position (A), and models followed the bias without
ever mentioning it: they wrote plausible chains rationalising the biased answer, and accuracy fell by
up to 36% across 13 BIG-Bench Hard tasks with GPT-3.5 and Claude 1.0.

> [!warning] Do not treat a chain of thought as an audit trail
> Reasoning text makes answers easier to debug and often catches errors, but a convincing chain is
> not evidence that the answer was reached for the stated reasons. Verify outputs against an eval set
> or an external check, not against the explanation.

## Costs and Limits

- **Tokens and latency.** Every reasoning token is billed and generated serially, so CoT makes each
  answer slower and more expensive; self-consistency and tree search multiply that.
- **Little gain on simple tasks.** Lookups, classification, and extraction rarely benefit, and extra
  reasoning can introduce errors on tasks the model would answer correctly at once.
- **Scale-dependent.** The original gains appeared only in large models; small models can produce
  fluent but wrong chains.
- **Arithmetic slips.** Natural-language chains still make calculation errors, which is what
  program-aided reasoning hands to an interpreter.

## Related Concepts

- [[concepts/ai_engineering/prompt_engineering|Prompt Engineering]] — the parent practice; CoT builds on its zero- and few-shot prompting
- [[concepts/ai_engineering/ai_engineer|AI Engineer]] — owns the eval suite that decides whether CoT's extra cost buys enough accuracy
- [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]] — IRCoT and agentic retrieval interleave reasoning steps with retrieval calls
- [[concepts/ai_engineering/agent_reasoning_patterns|Agent Reasoning Patterns (ReAct and ReWOO)]] — extend CoT with tool calls, either interleaving reasoning with actions (ReAct) or planning every call up front (ReWOO)
- [[concepts/ai_engineering/digital_superintelligence|Digital Superintelligence]] — why CoT faithfulness matters beyond accuracy: monitoring the reasoning of increasingly capable systems

## References

- Wei et al. (2022). [Chain-of-Thought Prompting Elicits Reasoning in Large Language Models](https://arxiv.org/abs/2201.11903).
- Kojima et al. (2022). [Large Language Models are Zero-Shot Reasoners](https://arxiv.org/abs/2205.11916). NeurIPS.
- Zhang et al. (2022). [Automatic Chain of Thought Prompting in Large Language Models](https://arxiv.org/abs/2210.03493).
- Wang et al. (2023). [Self-Consistency Improves Chain of Thought Reasoning in Language Models](https://arxiv.org/abs/2203.11171). ICLR.
- Zhou et al. (2023). [Least-to-Most Prompting Enables Complex Reasoning in Large Language Models](https://arxiv.org/abs/2205.10625). ICLR.
- Yao et al. (2023). [Tree of Thoughts: Deliberate Problem Solving with Large Language Models](https://arxiv.org/abs/2305.10601). NeurIPS.
- Gao et al. (2022). [PAL: Program-aided Language Models](https://arxiv.org/abs/2211.10435).
- Turpin et al. (2023). [Language Models Don't Always Say What They Think](https://arxiv.org/abs/2305.04388). NeurIPS.
- DeepSeek-AI (2025). [DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning](https://arxiv.org/abs/2501.12948). Nature.
- Anthropic. [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices).
