---
title: Prompt Engineering
tags: [ai-engineering, llm-applications, in-context-learning]
sources: ["https://arxiv.org/abs/2005.14165", "https://arxiv.org/abs/2202.12837", "https://arxiv.org/abs/2201.11903", "https://arxiv.org/abs/2205.11916", "https://arxiv.org/abs/2203.11171", "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices"]
created: 2026-10-29 18:52:09
updated: 2026-10-30 10:57:29
---

# Prompt Engineering

Prompt engineering is the practice of designing a language model's input — instructions, context,
examples, and output format — to get reliable behaviour on a task without changing the model's
weights. Its core techniques are zero-shot, one-shot, and few-shot prompting, which differ in how
many worked examples the prompt includes, and chain-of-thought prompting, which elicits
intermediate reasoning before the answer. It is one of the levers of the
[[concepts/ai_engineering/ai_engineer|AI Engineer]] role.

## Why It Matters

- **It is the cheapest lever.** A prompt change ships in minutes, needs no training data, and can be
  rolled back like any other configuration.
- **It is also the lowest-ceiling lever.** When a feature fails because the model lacks the facts,
  better retrieval (see
  [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]])
  or better task decomposition moves results further than any rewording.
- **Prompts are code.** They change model behaviour as much as a code change does, so they belong in
  version control and are judged by an eval suite, not by a few hand-picked outputs.

## Anatomy of a Prompt

| Part | Purpose |
| --- | --- |
| Instructions | The task, constraints, and what good output looks like |
| Context | Documents, data, or retrieved passages the answer depends on |
| Examples | Demonstrations of input and expected output (the "shots") |
| Input | The specific case to process |
| Output format | The structure to answer in, such as JSON or an answer wrapped in tags for extraction |

Delimiting each part, for example with XML-style tags, keeps instructions from being confused with
the data they apply to. Anthropic's guidance also recommends placing long documents near the top
of the prompt, above the query and instructions.

## Zero-Shot Prompting

The prompt describes the task in natural language and gives no examples; the model relies entirely
on what it learned in training.

```text
Classify the sentiment of this review as positive, negative, or neutral.
Review: "The battery lasts two days, but the screen scratches easily."
Sentiment:
```

Use it first: it is the shortest prompt, and instruction-tuned models handle most well-specified
tasks this way. Move to examples when the output format drifts, the labels are subtle, or the task
is unusual enough that a description alone is ambiguous.

## One-Shot Prompting

The prompt adds a single demonstration of input and expected output before the real input. One
example is usually enough to pin down a *format* (field order, length, tone), but it is risky for
*judgement*: the model tends to copy the lone example's surface features, so an unrepresentative
example skews every answer.

```text
Extract the product and the complaint as JSON.

Review: "Headphones broke after a week."
{"product": "headphones", "complaint": "broke after a week"}

Review: "The battery lasts two days, but the screen scratches easily."
```

## Few-Shot Prompting

The prompt includes several demonstrations. The terms come from the GPT-3 paper (Brown et al.,
2020), which framed zero-, one-, and few-shot as *in-context learning*: the model adapts to a task
from demonstrations in its input, with no gradient updates, and the paper found few-shot ability
improves sharply with model scale.

What the examples actually teach is subtler than it looks. Min et al. (EMNLP 2022) found that
randomly replacing the labels in demonstrations barely hurt classification accuracy across 12
models; the examples mattered mainly by showing the **label space**, the **distribution of inputs**,
and the **format**. The practical consequence: examples are most valuable for shape and coverage,
and correctness of the instructions still matters.

Guidelines for choosing examples (from Anthropic's prompting guide, which suggests three to five):

- **Relevant** — mirror the real inputs, not toy cases.
- **Diverse** — cover edge cases and vary irrelevant features, so the model does not latch on to an
  accidental pattern such as every example being short or every label being the same.
- **Delimited** — wrap examples in tags so they are not read as instructions.

| | Zero-shot | One-shot | Few-shot |
| --- | --- | --- | --- |
| Examples | None | One | Several, typically three to five |
| Prompt cost | Lowest | Low | Grows with each example, on every call |
| Best for | Clear, common tasks | Fixing an output format | Subtle labels, unusual formats, consistent style |
| Main risk | Ambiguous instructions | Over-copying the single example | Unrepresentative or unbalanced example set |

## Chain-of-Thought Prompting

Chain-of-thought prompting has the model write intermediate reasoning before its final answer, either
from worked examples (few-shot CoT) or a trigger phrase such as "Let's think step by step"
(zero-shot CoT), and it markedly improves multi-step problems. Its variants, the self-consistency
formula, reasoning models, and the faithfulness caveat are covered in
[[concepts/ai_engineering/chain_of_thought|Chain-of-Thought (CoT) Prompting]].

> [!tip] Start simple, then add structure
> Begin zero-shot with clear instructions and an eval set. Add examples when format or edge cases
> fail, and reasoning (a thinking mode, or CoT when unavailable) when multi-step accuracy fails.
> Change one thing at a time and re-run the evals.

## Limits

- **Prompts are model-specific.** A prompt tuned for one model or version can regress on the next,
  which is why the eval suite outlives the prompt.
- **Instructions are not a security control.** Text arriving through retrieved documents or tool
  output can carry prompt injection; restrictions belong at the tool and data boundary, not in a
  system-prompt sentence.
- **Shots cost tokens on every call.** Long few-shot prompts raise latency and cost at volume; at
  that point a smaller fine-tuned model may be the cheaper fix.

## Related Concepts

- [[concepts/ai_engineering/ai_engineer|AI Engineer]] — the role that owns prompt design, evals, and the decision of when prompting is no longer the right lever
- [[concepts/ai_engineering/chain_of_thought|Chain-of-Thought (CoT) Prompting]] — the reasoning technique split out of this note: variants, formulas, reasoning models, faithfulness
- [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]] — supplies the context section of the prompt, and the fix when the model lacks facts rather than instructions
- [[concepts/ai_engineering/model_context_protocol|Model Context Protocol (MCP)]] — how tools and data are wired into a model's context, where tool descriptions act as prompts too

## References

- Brown et al. (2020). [Language Models are Few-Shot Learners](https://arxiv.org/abs/2005.14165).
- Min et al. (2022). [Rethinking the Role of Demonstrations: What Makes In-Context Learning Work?](https://arxiv.org/abs/2202.12837) EMNLP.
- Wei et al. (2022). [Chain-of-Thought Prompting Elicits Reasoning in Large Language Models](https://arxiv.org/abs/2201.11903).
- Kojima et al. (2022). [Large Language Models are Zero-Shot Reasoners](https://arxiv.org/abs/2205.11916). NeurIPS.
- Wang et al. (2023). [Self-Consistency Improves Chain of Thought Reasoning in Language Models](https://arxiv.org/abs/2203.11171). ICLR.
- Anthropic. [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices).
