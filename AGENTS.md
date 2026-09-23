# Knowledge Base Agent Instructions

**This file is the canonical, non-negotiable constitution for every AI agent operating in this repository.** It defines the vault's structure, the required formats, and the exact procedures for reading and writing knowledge. There are no external scripts or plugins — the entire system's logic is encoded here.

The architecture is inspired by Andrej Karpathy's `llm-wiki` concept and the "AI Second Brain" pattern.

**Precedence:** `AGENTS.md` > any other instruction file in this repo (`GEMINI.md`, `.github/copilot-instructions.md`, etc.) > agent defaults. Other instruction files may only point to this one; they must not contradict it. If a user request conflicts with a rule here, say so and ask before proceeding.

**Skills:** detailed procedures live in `.skill/`. They are not auto-loaded — you must read them yourself. See §7 for the routing table.

---

## 1. Mandatory Rules

**These rules are absolute.**

1. **Markdown native.** Every operation is a read or write of a markdown file. Never introduce build scripts, databases, or plugin dependencies.
2. **Agent-driven.** You are the runtime. The file system is the only state. Read the vault to learn its state; write to the vault to change it.
3. **Compile, don't retrieve.** The wiki is pre-compiled knowledge, not an archive of clippings. Merge new information into the existing page. Never append a redundant section, never create a near-duplicate page, never paste raw source text verbatim.
4. **Atomic, complete transactions.** A task is finished only when the note, its wikilinks, `wiki/INDEX.md`, and `wiki/log.md` are all consistent. Never leave the audit trail half-updated.
5. **Every write is audited.** Any create, update, rename, or delete under `wiki/` MUST produce a `wiki/log.md` entry and a correct `wiki/INDEX.md`.
6. **Required frontmatter.** Every file under `wiki/concepts/` MUST have `title`, `tags`, `created`, and `updated` (see §3).
7. **Connect with wikilinks.** Every page must link to at least one related page, and be reachable from at least one other page. A page with no links is a defect.
8. **Single source of truth.** Exactly one page per concept. If two pages cover the same concept, merge them (see §6).
9. **Never fabricate.** Write only what the source material or the user states, or what is well-established general knowledge. If you infer or extrapolate, mark it explicitly. If a source is ambiguous, ask instead of guessing.
10. **Idempotent ingestion.** Processing the same raw file twice must not change the vault the second time.
11. **The skill registry is self-maintaining.** Whenever a skill under `.skill/` is added, renamed, retired, or has its purpose or triggers changed, update the §7 routing table in the *same* action. An unregistered or stale skill will never be found, so this is part of the transaction, not a follow-up.

### Prohibited without explicit user approval

- Deleting or wholesale-overwriting a note's existing content (merging is the default).
- Deleting anything from `raw/processed/`.
- Bulk edits across more than ~10 notes in one action.
- Rewriting `wiki/log.md` history — it is append-only; only correct factual typos.
- `git push`, force operations, or any history rewrite.
- Adding new top-level directories or otherwise changing the structure in §2.

---

## 2. Vault Structure

```text
.
├── AGENTS.md                  # This file. The constitution.
├── raw/                       # Intake queue: unprocessed notes, clippings, transcripts
│   └── processed/             # Archive of successfully ingested source files
└── wiki/                      # The compiled knowledge base
    ├── INDEX.md               # Master index of every wiki page, grouped by topic
    ├── log.md                 # Reverse-chronological activity log
    ├── concepts/              # Atomic notes — one file per concept
    └── assets/                # Images, PDFs, and other binaries linked from notes
```

**Naming conventions**

| Item                | Rule                                                                         | Example                                   |
| ------------------- | ---------------------------------------------------------------------------- | ----------------------------------------- |
| Concept filename    | `snake_case.md`, singular, no dates, no numbering                            | `master_data_management.md`               |
| `title` frontmatter | Title Case, human-readable, may include an acronym                           | `Master Data Management (MDM)`            |
| Asset filename      | `snake_case` with extension, prefixed by related concept                     | `data_quality_dimensions.png`             |
| Wikilink            | `[[concepts/file_name\|Display Text]]` — always vault-relative, always piped | `[[concepts/data_quality\|Data Quality]]` |

---

## 3. Note Format

Every file in `wiki/concepts/` follows this shape:

```markdown
---
title: Data Quality
tags: [data-governance]
created: 2026-09-22 09:11:46
updated: 2026-09-23 10:25:15
---

# Data Quality

One- or two-sentence definition or high-level summary of what this note contains that stands alone, linking the parent concept
such as [[concepts/data_governance|Data Governance]].

## Why It Matters

## <Topic-specific sections>

## Related Concepts

- [[concepts/data_stewardship|Data Stewardship]] — who is accountable for quality
- [[concepts/metadata_management|Metadata Management]] — where quality rules are documented
  
## References
- Additional outside URLs or citations go here.
```

**Frontmatter rules**

- `title` — string; must match the note's H1 heading.
- `tags` — YAML inline list, lowercase `kebab-case`. Every note carries 1–4 topical tags. Add `stub` while the note is a placeholder and **remove it** once the note is substantive.
- `created` — `YYYY-MM-DD HH:mm:ss`. Set once, never changed.
- `updated` — `YYYY-MM-DD HH:mm:ss`. Set on every content change.
- Timestamps must come from the real system clock (`date +"%Y-%m-%d %H:%M:%S"`). Never invent or copy a timestamp.

**Body rules**

- Start with an H1 matching `title`, then a standalone definition paragraph.
- Use `##` for sections; do not skip heading levels.
- Prose and bullets only. No raw HTML. Code fences only for actual code, config, or queries.
- Link the first meaningful mention of another concept; do not re-link the same concept in every paragraph.
- End with a `## Related Concepts` section that explains *why* each link matters, not just a bare list.
- Cite non-obvious external sources inline (`[Title](url)`) or in a `## Sources` section.

---

## 4. Workflow: Ingesting from `raw/`

1. **Scan.** List `raw/`, excluding `raw/processed/`. If empty, report that and stop.
2. **Read the source.** Read the file in full before deciding anything. Move binaries to `wiki/assets/` and describe what they depict.
3. **Identify concepts.** One raw file may contain several concepts — split it, one concept per note. Never create a note that merely mirrors the source document's shape.
4. **Search before writing.** Search `wiki/concepts/` by filename *and* by content (synonyms, acronyms, plurals), and check `wiki/INDEX.md`.
   - Match found → **Update**.
   - No match → **Create**.
   - Ambiguous or partially overlapping → ask the user; never create a near-duplicate.
5. **Write.**
   - **Create:** a new file per §3, filled in as far as the source supports.
   - **Update:** merge into the correct existing section. Rewrite sentences to integrate the new facts; do not bolt on an "Update" or "Additional Notes" section. Bump `updated`.
   - **Conflict:** if new information contradicts the page, do not silently overwrite. Keep the better-sourced claim and surface the conflict in your summary.
6. **Link both ways.** Add outbound wikilinks from the new or changed note, **and** add a link back from at least one related existing note so the page is reachable.
7. **Archive the source.** Move the raw file to `raw/processed/` **only after** steps 5–6 succeed. If ingestion fails or is aborted, leave it in `raw/` so it is retried.
8. **Update the audit trail.** Append to `wiki/log.md` and update `wiki/INDEX.md` (see §5). Mandatory, and always last.
9. **Report.** Summarize files ingested, notes created or updated, links added, and any conflicts or open questions.

### Direct requests (no `raw/` file)

When the user asks you to create or expand a note directly, skip steps 1, 2, and 7. Every other step applies unchanged.

---

## 5. Audit Trail

### `wiki/log.md`

Append-only, newest entry first, immediately under the `# Activity Log` heading. One line per logical action:

```markdown
- **YYYY-MM-DD**: <Verb> `[[concepts/note_name]]` — <what changed and why>. Source: `raw/processed/<file>`.
```

Use `Created`, `Updated`, `Expanded`, `Merged`, `Renamed`, or `Deleted` as the verb. Omit the `Source:` clause for direct requests. Never edit or reorder past entries.

### `wiki/INDEX.md`

The complete list of every page in `wiki/concepts/` — no more, no less. Group under `##` topic headings, alphabetize within each group, and use piped wikilinks:

```markdown
# Index

## Data Governance

- [[concepts/data_quality|Data Quality]]
```

Each page belongs to exactly one group. Create a new `##` group only when three or more pages justify it; otherwise use `## General`. After every write, verify the index matches the directory listing exactly.

---

## 6. Maintenance Operations

**Rename a note:** create the new file, move the content, update every inbound wikilink across the vault (search for the old name first), delete the old file, update `INDEX.md`, log as `Renamed`.

**Merge duplicates:** pick the richer page as the survivor, merge content per §1.3, repoint all inbound links to the survivor, delete the loser (ask first), update `INDEX.md`, log as `Merged`.

**Delete a note:** ask the user first. Then repoint or remove all inbound links, delete the file, remove it from `INDEX.md`, and log as `Deleted` with the reason.

**Lint pass:** when asked to audit the vault, check every item in §8 across all notes and report findings before making any fixes.

---

## 7. Skill Routing

Skills are reusable procedures stored as plain markdown under `.skill/`. Nothing loads them
automatically — when a trigger below applies, **read the `SKILL.md` before acting**, and read its
reference files when the skill tells you to. Skills elaborate on this constitution; they never
override it (see Precedence).

| Skill                                                    | What it covers                                                                                                | Read it when                                                                                                                             |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| [`obsidian-markdown`](.skill/obsidian-markdown/SKILL.md) | Obsidian Flavored Markdown: wikilinks, embeds, callouts, frontmatter properties, comments, and block references | Writing or editing any note body; the user mentions wikilinks, callouts, embeds, or frontmatter; a link or embed is not rendering right   |
| [`tag-taxonomy`](.skill/tag-taxonomy/SKILL.md)           | The controlled tag vocabulary, the mandatory 1–4 tag set, banned tags, and the tag audit workflow             | **Every time you assign or change a tag**; the user says "fix my tags", "normalize tags", "tag audit", "my tags are a mess", or asks what tags to use or how to add one |

**Adding a skill:** create `.skill/<skill-name>/SKILL.md` with `name` and `description` frontmatter, put any long reference material in `.skill/<skill-name>/references/`, and add a row to the table above. A skill that is not listed here will not be found.

### Keeping this table in sync

This table is the skill registry, and it is maintained by you — there is no script (§1.1). Per §1.11, reconcile it **in the same action** that touches a skill:

| Trigger                                           | Required table change                                                                        |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| New `.skill/<name>/SKILL.md` created              | Add a row, alphabetically by skill name                                                       |
| A skill's `description` or scope changed          | Rewrite that row's **What it covers** and **Read it when** cells to match                     |
| A skill folder renamed                            | Update the row's name and link; fix any other file that references the old path               |
| A skill deleted or retired                        | Remove the row (ask the user before deleting the folder itself)                               |
| Reference files added or removed under a skill    | No change here — each `SKILL.md` links its own references                                     |

**Derive rows from the source, never from memory.** Read the skill's frontmatter `description` and condense it: **What it covers** is the subject matter, **Read it when** is the trigger conditions, phrased so an agent can match them against a user request. Keep both cells to one line.

**Verify before reporting done.** Every `.skill/*/SKILL.md` on disk has exactly one row; every row points at a file that exists; no row describes a skill's old behaviour. If the user asks you to audit skills, check those three things and report before fixing anything.

---

## 8. Definition of Done

Verify all of the following before reporting completion:

- [ ] Every touched note has all four frontmatter fields, and `updated` reflects the real current time.
- [ ] Every touched note has an H1 matching `title` and a `## Related Concepts` section.
- [ ] Every wikilink resolves to a file that exists; none are broken or unpiped.
- [ ] New notes are reachable from at least one existing note.
- [ ] `wiki/INDEX.md` lists exactly the files present in `wiki/concepts/`.
- [ ] `wiki/log.md` has one correctly formatted, correctly dated entry per logical action.
- [ ] Successfully ingested sources were moved to `raw/processed/`; failed ones remain in `raw/`.
- [ ] No duplicate concept pages were introduced.
- [ ] Every skill touched under `.skill/` has a matching, current row in the §7 routing table.

---

## References

- Andrej Karpathy's `llm-wiki` gist: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
