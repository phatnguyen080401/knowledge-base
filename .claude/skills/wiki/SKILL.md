---
name: wiki
description: Run a knowledge-base workflow by subcommand — lint, create, ingest, ask, tags, commit. A thin router to the procedures in AGENTS.md and .skill/.
argument-hint: "<lint|create|ingest|ask|tags|commit> [args]"
disable-model-invocation: true
---

# /wiki

Arguments: `$ARGUMENTS`

The first word of the arguments is the **subcommand**; everything after it is the **argument**
passed to that workflow. This file only routes. The procedures live in `AGENTS.md` and `.skill/`,
and `AGENTS.md` wins on any conflict.

1. Read `AGENTS.md` before acting.
2. Look up the subcommand below, read the file it names in full, and follow it exactly.

| Subcommand          | Read                                                                 | Does                                                                   |
| ------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `lint`              | `.skill/wiki-lint/SKILL.md`                                          | Whole-vault lint pass; reports and waits for approval before any fix   |
| `create <topic>`    | `.skill/wiki-create/SKILL.md`                                        | Creates a note on `<topic>`, or expands the existing one               |
| `ingest [file]`     | `AGENTS.md` §4                                                       | Ingests everything in `raw/`, or only `[file]` when given              |
| `ask <question>`    | `AGENTS.md` §5                                                       | Answers from the vault with citations, files the answer back, logs it  |
| `tags [scope]`      | `.skill/tag-taxonomy/SKILL.md` + `references/audit.md`               | Tag audit across the vault, or only `[scope]` (a folder or note)       |
| `commit`            | `.skill/git-commit-helper/SKILL.md`                                  | Commits the current changes with a Conventional Commits message        |

If the subcommand is missing or not in the table, print the table as usage and stop. If a
subcommand that needs an argument (`create`, `ask`) has none, ask for it instead of guessing.
