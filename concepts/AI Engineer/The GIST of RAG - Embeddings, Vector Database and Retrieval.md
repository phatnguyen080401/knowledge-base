# RAG
# React (reasoning and action)
- Chain-of-Thought prompting
# ReWOO (reasoning without observation)
The ReWOO method, unlike ReAct, eliminates the dependence on tool outputs for action planning. Instead, agents plan upfront. Redundant tool usage is avoided by anticipating which tools to use upon receiving the initial prompt from the user. This approach is desirable from a human-centered perspective because the user can confirm the plan before it is executed.

The ReWOO workflow is made up of three modules. In the planning module, the agent anticipates its next steps given a user's prompt. The next stage entails collecting the outputs produced by calling these tools. Lastly, the agent pairs the initial plan with the tool outputs to formulate a response. This planning ahead can greatly reduce token usage and computational complexity and the repercussions of intermediate tool failure

## Types of AI agents
## Context Window
## Embeddings
Dimensonality
Retrieval -> Scoring and Chunk Overlap strategy

Context window is the maximum number of tokens a LLM can process at once, it includes your input and model's output 