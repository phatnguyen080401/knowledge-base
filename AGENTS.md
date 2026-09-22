# Obsidian Knowledge Base Agent Framework

This document defines the roles, skills, and operating instructions for an AI assistant managing this Obsidian vault. It serves as the central "API" or "schema" that governs the agent's behavior, ensuring that the knowledge base is maintained in a consistent, structured, and intelligent manner.

The architecture is inspired by Andrej Karpathy's `llm-wiki` concept and the practical implementation proposed by MindStudio for an "AI Second Brain."

---

## Core Principles

1.  **Markdown Native:** All operations are based on reading and writing markdown files. There are no external scripts, plugins, or dependencies. The entire system's logic is encoded in this document.
2.  **Agent-Driven:** The agent (you, a large language model) is responsible for executing the skills defined herein. You read the state of the vault from the files and modify it by writing back to them.
3.  **Stateless & Atomic Operations:** Each skill execution is an atomic transaction. You read the necessary files, perform the modifications, and write the result. The state is the file system itself.
4.  **Auditable & Idempotent:** Every significant action that modifies the wiki is logged in `wiki/log.md`. Ingestion operations are idempotent—processing the same raw file twice will not create duplicate content.

---

## Vault Structure

```text
.
├── AGENTS.md                  # Constitution and instruction manual for the agent (this file)
├── raw/                       # Intake queue for new information, notes, and clippings
│   └── processed/             # Archive of successfully ingested files (prevents re-processing)
└── wiki/                      # Core, structured knowledge base
    ├── INDEX.md               # Master index — lists every source file and every wiki page, updated automatically after each processing run
    ├── log.md                 # Chronological activity log (ingests, updates, lints)
    ├── concepts/              # Individual, atomic notes on specific topics, concepts, and entities
    └── assets/                # Images, PDFs, and other non-markdown assets linked from the wiki
```

---

## Skill Routing

TBC

## Visibility Tags (optional)
TBC

## Core Principles

- **Compile, don't retrieve.** The wiki is pre-compiled knowledge. Update existing pages — don't append or duplicate.
- **Track everything.** Update `index.md` and `log.md` after any write operation.
- **Connect with `[[wikilinks]]`.** Every page should link to related pages. This is what makes it a knowledge graph, not a folder of files.
- **Frontmatter is required.** Every wiki page needs: `title`, `tags`, `created`, `updated`.
- **Single source of truth.** Visibility tags shape how content is surfaced — they don't duplicate or separate it.

## Architecture Reference

For the full pattern (three-layer architecture, page templates, project org), read `.skills/llm-wiki/SKILL.md`.
