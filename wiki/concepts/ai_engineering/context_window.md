---
title: Context Window
tags: [ai-engineering, llm-applications, model-operations, in-context-learning]
created: 2026-10-31 10:49:23
updated: 2026-10-31 11:07:29
---

# Context Window

The context window is the maximum number of tokens a large language model can process in one call. It covers both the input and the output the model generates. Everything the model "knows" about the current task, beyond what is in its weights, has to fit inside it, which makes it the hard budget behind [[concepts/ai_engineering/prompt_engineering|Prompt Engineering]] and [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]].

## Why It Matters

- **It is a hard limit.** A request whose input plus requested output exceeds the window is rejected by the API or silently truncated by the application around it.
- **It is the model's only working memory.** A model call is stateless. A chat "remembers" earlier turns only because the application resends them inside the window on every call.
- **It drives cost and latency.** Providers bill per input and output token, and the time before the first output token grows with input length, so a full window is the most expensive and slowest call.
- **Advertised size is not usable size.** Models retrieve and reason over facts less reliably as the context grows, and especially in the middle of it, so the effective window is smaller than the one on the specification sheet.

## Tokens

The window is measured in **tokens**, the sub-word units produced by the model's tokenizer, not in characters or words. For English prose a common rule of thumb is about four characters, or three-quarters of a word, per token. Code, non-English text, numbers, and unusual identifiers usually take more tokens per character. Tokenizers differ between model families, so the same text has a different token count on each, and a budget must be measured with the target model's own tokenizer.

## What Fills the Window

Every token the model reads or writes in a call counts against the same budget:

| Component | Notes |
| --- | --- |
| System prompt | Instructions, persona, output format; resent on every call |
| Tool definitions | Each tool's name, description, and JSON schema, whether or not it is used |
| Conversation history | Every previous user and assistant turn the application chooses to resend |
| Retrieved context | Documents or chunks inserted by a RAG pipeline |
| Tool results | Observations returned by tools in an agent loop, such as search results, file contents, or API responses |
| The current request | The user's latest message, images, or files |
| Reasoning tokens | For reasoning models, the hidden or visible thinking generated before the answer |
| The output | The answer itself, capped separately by a maximum output-token setting |

$$
\text{input tokens} + \text{output tokens} \le \text{context window}
$$

The maximum output length is usually a separate, smaller limit than the window. A model with a very large window may still cap a single response at a fraction of it.

## Why the Window Is Finite

- **Attention cost.** In a standard transformer, every token attends to every earlier token, so attention compute grows with the square of the sequence length.
- **KV-cache memory.** During generation the model keeps a key and value vector per token per layer. That cache grows linearly with context length and is often what limits how many long requests a GPU can serve at once.
- **Training length.** A model handles positions reliably only up to roughly the lengths it was trained or extended on. Long-context models are trained or fine-tuned specifically for those lengths.

Windows grew from 2,048 tokens in GPT-3 to hundreds of thousands, and in some models a million or more. Larger windows reduce how often an application has to choose what to leave out, but they do not remove the cost, latency, and accuracy reasons to keep the context small.

## Effective vs. Advertised Context

- **Lost in the middle.** Models attend best to the start and end of a long context and worst to the middle. The RAG note's [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki#Context Assembly|Context Assembly]] section covers the ordering this implies.
- **Distractors.** Irrelevant but plausible text degrades answers, so adding more retrieved chunks can lower quality even while it raises recall.
- **Simple tests flatter long context.** Finding one planted sentence in a long document ("needle in a haystack") is easier than combining several facts spread across it. A model that passes the first can still fail the second.

> [!important] Fill the window with what the task needs, not with what fits
> The context window is a ceiling, not a target. Curating fewer, better tokens usually improves accuracy, cost, and latency at the same time.

## Managing the Window

| Strategy | How it works | Trade-off |
| --- | --- | --- |
| **Retrieval** | Store knowledge outside the model and insert only the relevant passages per request (RAG) | Answer quality now depends on retrieval quality |
| **Sliding window** | Resend only the most recent $n$ turns of a conversation | Early instructions and facts drop out |
| **Summarization or compaction** | Replace older turns or tool results with a model-written summary | Lossy; details the summary omitted are gone |
| **External memory** | The model writes notes or state to a file or store and reads them back when needed | Needs tools and a discipline for what to save |
| **Trimming tool output** | Return only the fields or lines the task needs from a tool, not the whole response | Tools must be designed for it |
| **Sub-agents** | Hand a sub-task to a separate call with its own window, and keep only its result | Extra calls; the sub-agent cannot see the parent's full context |
| **Prompt caching** | Reuse the processed form of a stable prompt prefix across calls | Cuts cost and latency of repeated tokens, but does not enlarge the window |

Agent loops such as [[concepts/ai_engineering/agent_reasoning_patterns#ReAct (Reasoning and Acting)|ReAct]] stress the window most, because every thought, action, and observation is appended and resent on each step. [[concepts/ai_engineering/agent_reasoning_patterns#ReWOO (Reasoning Without Observation)|ReWOO]] was designed partly to avoid that growth.

## Related Concepts

- [[concepts/ai_engineering/retrieval_as_reasoning_self_evolving_agent_native_retrieval_via_llm_wiki|Retrieval-Augmented Generation (RAG)]] — the main technique for working with knowledge far larger than the window, and where context-assembly rules live
- [[concepts/ai_engineering/prompt_engineering|Prompt Engineering]] — what goes into the window, and why long few-shot prompts cost tokens on every call
- [[concepts/ai_engineering/chain_of_thought|Chain-of-Thought (CoT) Prompting]] — reasoning tokens are output tokens, so longer reasoning consumes the same budget
- [[concepts/ai_engineering/agent_reasoning_patterns|Agent Reasoning Patterns (ReAct and ReWOO)]] — ReAct's growing trace is a common cause of context overflow, and ReWOO keeps prompts short by planning once
- [[concepts/ai_engineering/retrieval_scoring|Retrieval Scoring and Ranking]] — decides which retrieved chunks earn a place in the window
- [[concepts/ai_engineering/model_context_protocol|Model Context Protocol (MCP)]] — every tool an MCP server exposes adds its definition to the window
- [[concepts/ai_engineering/embeddings|Embeddings]] — the representation that lets retrieval pick what enters the window by meaning
