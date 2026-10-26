# Knowledge Base Agent Instructions

**The canonical, non-negotiable constitution for every AI agent in this repository.** It defines
the vault's rules, structure, and note format. There are no scripts or plugins: you are the runtime,
and the procedures live as markdown skills under `.skill/` (§8). The architecture follows Andrej
Karpathy's [`llm-wiki`](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and the
"AI Second Brain" pattern.

**Precedence:** `AGENTS.md` > any other instruction file in this repo (`GEMINI.md`,
`.github/copilot-instructions.md`, etc.) > agent defaults. Other instruction files may only point
here. Skills elaborate on this file and never override it. If a user request conflicts with a rule
here, say so and ask before proceeding.

**Read the skill before you act.** Skills are not auto-loaded. Find the task in §8 and read that
`SKILL.md` (and the references it names) first.

**One clock reading per request.** Read the system clock once at write time and reuse it for every
`created`/`updated` and the `wiki/log.md` timestamp. Bash: `date +"%Y-%m-%d %H:%M:%S"`; PowerShell:
`Get-Date -Format "yyyy-MM-dd HH:mm:ss"`. Never invent or copy a timestamp.

---

## 1. Mandatory Rules

**These rules are absolute.**

1. **Markdown native.** Every operation is a read or write of a markdown file. Never introduce build scripts, databases, or plugin dependencies.
2. **Agent-driven.** The file system is the only state. Read the vault to learn its state; write to the vault to change it.
3. **Compile, don't retrieve.** Merge new information into the existing page. Never append a redundant section, create a near-duplicate page, or paste raw source text verbatim.
4. **Atomic, complete transactions.** A task is finished only when the note, its wikilinks, `wiki/INDEX.md`, and `wiki/log.md` are all consistent.
5. **Every write under `wiki/` is audited, and only those.** Any create, update, rename, or delete under `wiki/` produces one `wiki/log.md` entry and a correct `wiki/INDEX.md`. Changes outside `wiki/` (`AGENTS.md`, `.skill/`, plumbing) get no entry of their own; when one accompanies a wiki change, name it in one clause of that entry.
6. **Required frontmatter.** Every file under `wiki/concepts/` has `title`, `tags`, `created`, and `updated` (§3).
7. **Connect with wikilinks.** Every page links to at least one related page and is reachable from at least one other page.
8. **Single source of truth.** Exactly one page per concept. If two pages cover the same concept, merge them (§7).
9. **Never fabricate.** Write only what the source or the user states, or well-established general knowledge. Mark inference explicitly. If a source is ambiguous, ask instead of guessing.
10. **Idempotent ingestion.** Processing the same raw file twice must not change the vault the second time.
11. **The skill registry is self-maintaining.** Adding, renaming, retiring, or re-scoping a skill under `.skill/` updates the §8 table in the *same* action.
12. **Knowledge compounds from questions too.** If an answer contains synthesis, a comparison, or a correction the vault does not hold, file it back (§5).

### Prohibited without explicit user approval

- Deleting or wholesale-overwriting a note's existing content (merging is the default).
- Deleting anything from `raw/processed/`.
- Bulk edits across more than ~10 notes in one action.
- Rewriting `wiki/log.md` history. It is append-only; only correct factual typos.
- `git push`, force operations, or any history rewrite.
- Adding new top-level directories, a new domain folder, or otherwise changing the structure in §2.

---

## 2. Vault Structure

```text
.
├── AGENTS.md              # This file
├── .claude/skills/        # Symlink to .skill/: every skill is a Claude Code command (§8)
├── .skill/                # Skill procedures (§8)
├── raw/                   # Intake queue: unprocessed notes, clippings, transcripts
│   ├── assets/            # Images, PDFs, and other binaries linked from notes
│   └── processed/         # Archive of ingested source files
└── wiki/
    ├── INDEX.md           # Every page, grouped by folder (§6)
    ├── log.md             # Append-only activity log (§6)
    └── concepts/<domain_folder>/[<tech_subfolder>/]<note>.md
```

**Filing.** Every note lives in the folder of its `domain` tag (`databases` → `concepts/databases/`).
Folder and tag always agree; changing the domain tag is a rename (§7). Nothing sits loose at the
root of `concepts/`. The authoritative list of domain folders is the `domain` table in
[`.skill/tag-taxonomy/references/taxonomy.md`](.skill/tag-taxonomy/references/taxonomy.md).

A **tech subfolder**, one level deep only, clusters a product family with its own namesake hub note
(`data_engineering/dbt/` with `dbt.md`). Every note inside carries that product's `tech` tag.

| Item                | Rule                                                        | Example                                                  |
| ------------------- | ----------------------------------------------------------- | -------------------------------------------------------- |
| Folder name         | `snake_case` of the `domain` tag                            | `databases/`, `data_engineering/dbt/`                    |
| Concept filename    | `snake_case.md`, singular, no dates, no numbering           | `master_data_management.md`                              |
| `title`             | Title Case, may include an acronym                          | `Master Data Management (MDM)`                           |
| Asset filename      | `snake_case`, prefixed by the related concept               | `data_quality_dimensions.png`                            |
| Wikilink            | Full vault-relative path, always piped                      | `[[concepts/data_governance/data_quality\|Data Quality]]` |

---

## 3. Note Format

One concept per note. Every file in `wiki/concepts/` follows this shape:

```markdown
---
title: Data Quality
tags: [data-governance, data-quality, data-validation]
sources: [raw/processed/dama_dmbok_ch11.md, "https://example.org/article"]
created: 2026-09-22 09:11:46
updated: 2026-09-23 10:25:15
---

# Data Quality

A standalone one- or two-sentence definition linking the parent concept, such as
[[concepts/data_governance/data_governance|Data Governance]].

## Why It Matters

## <Topic-specific sections>

## Open Questions & Disagreements

- <Claim A> (source X) conflicts with <claim B> (source Y). Unresolved because …

## Related Concepts

- [[concepts/data_governance/data_stewardship|Data Stewardship]] — who is accountable for quality

## References

- Outside URLs or citations.
```

**Frontmatter**

- `title` matches the H1.
- `tags` are chosen with the [`tag-taxonomy`](.skill/tag-taxonomy/SKILL.md) skill, which sets the facet rules. `stub` marks a placeholder and is removed once the note is substantive.
- `tags` and `sources` are always inline one-line YAML lists (`[a, b]`), never block lists.
- `sources` lists every `raw/processed/<file>` and external URL (quoted) that contributed a fact. Append on every ingest; never remove an entry. No `sources` means general knowledge or direct user input.
- `created` and `updated` use `YYYY-MM-DD HH:mm:ss` from the real clock. `created` is set once; `updated` changes on every content change.

**Body**

- H1 matching `title`, then a standalone definition paragraph. `##` sections, no skipped levels.
- Prose and bullets only; no raw HTML; code fences only for real code, config, or queries.
- Link the first meaningful mention of another concept, not every mention.
- `## Open Questions & Disagreements` appears whenever sources conflict, a claim is unverified, or you extrapolated. Name both positions and their sources; never silently pick a winner. The note carries `needs-review` exactly while this section is non-empty; delete the section once resolved.
- `## Related Concepts` explains *why* each link matters. `## References`, if any, comes last.

---

## 4. Ingesting from `raw/`

Follow [`wiki-ingest`](.skill/wiki-ingest/SKILL.md). Invariants: read each source in full; search the
vault by name and content before writing, and ask when overlap is ambiguous; merge, don't
duplicate; record conflicts in the note; archive a source to `raw/processed/` only after its notes
are written and linked. A direct request with no `raw/` file follows
[`wiki-create`](.skill/wiki-create/SKILL.md).

## 5. Answering Questions

Follow [`wiki-query`](.skill/wiki-query/SKILL.md). Invariants: read `wiki/INDEX.md` before any
page; cite every claim with the page's wikilink; label anything from general knowledge as *outside
the wiki*; file new synthesis, gaps, conflicts, and corrections back; log one `query` entry even
when nothing was filed. Never answer a vault question from memory alone.

## 6. Audit Trail

Formats and examples are in [`wiki-audit-trail`](.skill/wiki-audit-trail/SKILL.md). Invariants:

- **`wiki/log.md`:** one entry per request, newest first, one line of about 40 words, tagged
  `ingest`, `query`, `lint`, or `maintain`. It is a pointer to the change, not a copy of the note.
  Past entries are never edited or reformatted, whatever their format.
- **`wiki/INDEX.md`:** lists exactly the files in `wiki/concepts/`, grouped to mirror the folder
  tree, each with a one-line summary (plus `**Stub.**` for stubs). Verify it against the directory
  listing after every write.

## 7. Maintenance Operations

- **Rename:** create the new file, move the content, update every inbound wikilink (search for the old name first), delete the old file, update `INDEX.md`, log `Renamed`.
- **Merge duplicates:** keep the richer page, merge per §1.3, repoint inbound links, delete the loser (ask first), update `INDEX.md`, log `Merged`.
- **Delete:** ask first. Repoint or remove inbound links, delete the file, remove it from `INDEX.md`, log `Deleted` with the reason.
- **Lint pass:** follow [`wiki-lint`](.skill/wiki-lint/SKILL.md). Run the structural *and* semantic checks (§9), report before fixing, log `Audited`.

---

## 8. Skill Routing

When a trigger applies, read the `SKILL.md` before acting. Each skill's `description` frontmatter
lists its full trigger phrases.

| Skill                                                    | Read it when                                                                              |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [`git-commit-helper`](.skill/git-commit-helper/SKILL.md) | Committing, staging, or writing, fixing, or amending a commit message                     |
| [`tag-taxonomy`](.skill/tag-taxonomy/SKILL.md)           | **Every create, update, move, or filing of a note**; choosing tags; tag audits (`references/audit.md`) |
| [`wiki-audit-trail`](.skill/wiki-audit-trail/SKILL.md)   | Writing any `wiki/log.md` entry or editing `wiki/INDEX.md`                                |
| [`wiki-create`](.skill/wiki-create/SKILL.md)             | Creating, expanding, or stubbing a note on direct request (`/wiki-create`)                |
| [`wiki-ingest`](.skill/wiki-ingest/SKILL.md)             | Ingesting files from `raw/` (`/wiki-ingest`)                                              |
| [`wiki-lint`](.skill/wiki-lint/SKILL.md)                 | Lint pass, vault audit, health check, broken links, orphans, duplicates (`/wiki-lint`)    |
| [`wiki-query`](.skill/wiki-query/SKILL.md)               | Answering a question about the wiki's subject matter (`/wiki-query`)                      |

`.claude/skills` is a symlink to `.skill/`, so every skill is also a Claude Code slash command
named after its folder (`/wiki-create`). Command metadata (`argument-hint`, `user-invocable`) lives
in the skill's frontmatter.

**Keeping the table in sync (§1.11).** A new skill gets `.skill/<name>/SKILL.md` with `name` (equal to
its folder and command name) and `description` frontmatter, long material in `references/`, and a
row here, alphabetical by name. Derive each row from the skill's `description`, never from memory, in one line. A renamed skill
updates its row and every file referencing the old path. A retired skill loses its row; ask before
deleting its folder. Before reporting done, confirm every `.skill/*/SKILL.md` has exactly one row
and every row's link exists.

---

## 9. Definition of Done

**Structural checks.** Run on every write, and across all notes in a lint pass.

- [ ] Touched notes have all four required frontmatter fields, `updated` from the real clock, an H1 matching `title`, and `## Related Concepts`.
- [ ] Tags pass the `tag-taxonomy` Definition of Done, and the folder matches the `domain` tag.
- [ ] Every wikilink is piped and resolves; new notes are reachable from an existing note.
- [ ] `wiki/INDEX.md` lists exactly the files in `wiki/concepts/`, with current summaries.
- [ ] `wiki/log.md` has exactly one short entry for the request (none if nothing under `wiki/` changed, except a `query`); no past entry was edited.
- [ ] Ingested sources are in `sources` and in `raw/processed/`; failed ones remain in `raw/`.
- [ ] `stub` and `needs-review` tags match the note's actual state.
- [ ] No duplicate concept pages; every touched skill has a current §8 row.

**Semantic checks.** Required in a lint pass and applied to touched pages on every write; report
as findings with a proposed fix, never silently correct: contradictions, stale claims, orphans and
weak links, missing pages, hollow hubs, unsourced claims, and next questions. Methods are in
[`wiki-lint`](.skill/wiki-lint/SKILL.md).
