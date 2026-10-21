# Knowledge Base Agent Instructions

**This file is the canonical, non-negotiable constitution for every AI agent operating in this repository.** It defines the vault's structure, the required formats, and the exact procedures for reading and writing knowledge. There are no external scripts or plugins — the entire system's logic is encoded here.

The architecture is inspired by Andrej Karpathy's `llm-wiki` concept and the "AI Second Brain" pattern.

**Precedence:** `AGENTS.md` > any other instruction file in this repo (`GEMINI.md`, `.github/copilot-instructions.md`, etc.) > agent defaults. Other instruction files may only point to this one; they must not contradict it. If a user request conflicts with a rule here, say so and ask before proceeding.

**Skills:** detailed procedures live in `.skill/`. They are not auto-loaded — you must read them yourself. See §8 for the routing table.

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
8. **Single source of truth.** Exactly one page per concept. If two pages cover the same concept, merge them (see §7).
9. **Never fabricate.** Write only what the source material or the user states, or what is well-established general knowledge. If you infer or extrapolate, mark it explicitly. If a source is ambiguous, ask instead of guessing.
10. **Idempotent ingestion.** Processing the same raw file twice must not change the vault the second time.
11. **The skill registry is self-maintaining.** Whenever a skill under `.skill/` is added, renamed, retired, or has its purpose or triggers changed, update the §8 routing table in the *same* action. An unregistered or stale skill will never be found, so this is part of the transaction, not a follow-up.
12. **Knowledge compounds from questions too.** Answering a question is not a read-only act. If the answer contains synthesis, a comparison, or a correction the vault does not already hold, file it — as an edit to an existing note, a new page, a stub, or an entry under `## Open Questions & Disagreements`. An insight left in chat history is an insight lost (see §5).

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
sources: [raw/processed/dama_dmbok_ch11.md, "https://example.org/article"]
created: 2026-09-22 09:11:46
updated: 2026-09-23 10:25:15
---

# Data Quality

One- or two-sentence definition or high-level summary of what this note contains that stands alone, linking the parent concept
such as [[concepts/data_governance|Data Governance]].

## Why It Matters

## <Topic-specific sections>

## Open Questions & Disagreements

- <Claim A> (source X) conflicts with <claim B> (source Y). Unresolved because …

## Related Concepts

- [[concepts/data_stewardship|Data Stewardship]] — who is accountable for quality
- [[concepts/metadata_management|Metadata Management]] — where quality rules are documented
  
## References
- Additional outside URLs or citations go here.
```

**Frontmatter rules**

- `title` — string; must match the note's H1 heading.
- `tags` — YAML inline list, lowercase `kebab-case`. Every note carries at least 1 topical tags. Add `stub` while the note is a placeholder and **remove it** once the note is substantive.
- `sources` — optional YAML inline list. Every `raw/processed/<file>` path and external URL that contributed a fact to this page. **Append on every ingest; never remove an entry** — this is the provenance trail that makes §1.9 auditable after the fact. Quote bare URLs. A note with no `sources` rests on well-established general knowledge or direct user input.
- `created` — `YYYY-MM-DD HH:mm:ss`. Set once, never changed.
- `updated` — `YYYY-MM-DD HH:mm:ss`. Set on every content change.
- Timestamps must come from the real system clock (`date +"%Y-%m-%d %H:%M:%S"`). Never invent or copy a timestamp.

**Body rules**

- Start with an H1 matching `title`, then a standalone definition paragraph.
- Use `##` for sections; do not skip heading levels.
- Prose and bullets only. No raw HTML. Code fences only for actual code, config, or queries.
- Link the first meaningful mention of another concept; do not re-link the same concept in every paragraph.
- Include `## Open Questions & Disagreements` whenever sources conflict, a claim is unverified, or you had to extrapolate. Name both positions and their sources; never silently pick a winner. Tag the note `needs-review` while the section is non-empty, and delete the section once everything in it is resolved.
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
   - **Conflict:** if new information contradicts the page, do not silently overwrite. Keep the better-sourced claim in the body, **and record both positions with their sources under `## Open Questions & Disagreements`** — a conflict raised only in your chat summary is a conflict that will be forgotten. Add `needs-review` to `tags`.
6. **Link both ways.** Add outbound wikilinks from the new or changed note, **and** add a link back from at least one related existing note so the page is reachable.
7. **Archive the source.** Move the raw file to `raw/processed/` **only after** steps 5–6 succeed. If ingestion fails or is aborted, leave it in `raw/` so it is retried.
8. **Update the audit trail.** Append to `wiki/log.md` and update `wiki/INDEX.md` (see §6), and append each ingested source to the note's `sources` frontmatter. Mandatory, and always last.
9. **Report.** Summarize files ingested, notes created or updated, links added, and any conflicts or open questions.

### Direct requests (no `raw/` file)

When the user asks you to create or expand a note directly, skip steps 1, 2, and 7. Every other step applies unchanged.

---

## 5. Workflow: Answering Questions

The wiki is the answer source. This workflow applies whenever the user asks a question about
its subject matter rather than asking for an edit.

1. **Index first.** Read `wiki/INDEX.md` and shortlist candidate pages from the summaries. Only
   then open files. Do not search the whole vault before consulting the index.
2. **Read the shortlist in full.** Read the pages, not fragments of them. Follow
   `## Related Concepts` links one hop out when the question spans concepts.
3. **Answer with citations.** Every substantive claim carries the piped wikilink of the page it
   came from, so the user can tell vault knowledge from your own.
4. **Declare the gaps — never fill them silently.** If the wiki does not cover part of the
   question, say so explicitly and label anything you add from general knowledge as *outside the
   wiki*. Answering from your own weights while implying the vault said it is the worst failure
   of this workflow, and a §1.9 violation.
5. **File the answer back.** Per §1.12, decide which of these applies — more than one may:
   - The answer merely restates what a page already says → file nothing.
   - The answer synthesized two or more pages into something neither contains → a new page per
     §3, or a new section on the better-fitting page.
   - The question exposed a missing concept → create a `stub`, linked both ways.
   - The question exposed a conflict or an unverified claim → record it under
     `## Open Questions & Disagreements` on the relevant page and tag it `needs-review`.
   - The answer corrected a page → fix the page in the same action and bump `updated`.

   When it is a judgement call, propose the page and ask before writing.
6. **Log it.** One `Answered` entry per question (see §6), naming the pages read and what was
   filed — including `Filed: nothing` when that was the right call. The log covers all three
   operations, not only ingestion.

**Never** answer a vault question purely from memory without reading the pages, and never let a
question that produced something worth keeping leave the vault unchanged.

---

## 6. Audit Trail

### `wiki/log.md`

Append-only, newest entry first, immediately under the `# Activity Log` heading. One line per logical action:

```markdown
- **YYYY-MM-DD HH:mm:ss** · <operation> · <Verb> `[[concepts/note_name]]` — <what changed and why>. Source: `raw/processed/<file>`.
```

- **Timestamp** — full date *and* time, from the real system clock (`date +"%Y-%m-%d %H:%M:%S"`), so the log records *when* the vault changed and entries written on the same day stay ordered. Never invent or copy a timestamp.
- **Operation** — exactly one of `ingest`, `query`, `lint`, or `maintain`, matching the workflow that produced the entry. The `·` separators make the log greppable by operation: `grep ' · lint · ' wiki/log.md`.
- **Verb** — `Created`, `Updated`, `Expanded`, `Merged`, `Renamed`, `Deleted`, `Answered` (§5), or `Audited` (§7 lint pass).
- Omit the `Source:` clause for direct requests.

A `query` entry names the question, the pages read, and what was filed:

```markdown
- **YYYY-MM-DD HH:mm:ss** · query · Answered "<question>". Read: `[[concepts/a]]`, `[[concepts/b]]`. Filed: <new page / section / stub / open question / nothing, and why>.
```

**The log is append-only.** Never edit, reorder, reformat, or condense a past entry; only correct a factual typo. Entries written before this format was adopted use a date-only `- **YYYY-MM-DD**:` prefix and are left exactly as they are — the mixed format is the expected state, not a defect to clean up.

### `wiki/INDEX.md`

The complete list of every page in `wiki/concepts/` — no more, no less. Group under `##` topic headings, alphabetize within each group, and use piped wikilinks. **Every entry carries a one-line summary** after an em dash, written so the agent can shortlist from the index alone without opening files (§5.1). Append `**Stub.**` to the summary of any page tagged `stub`. A hub page may be listed first in its group, ahead of alphabetical order:

```markdown
# Index

## Data Governance

- [[concepts/data_quality|Data Quality]] — the six dimensions and their checks, where defects originate, and the measure-remediate lifecycle.
```

Each page belongs to exactly one group. Create a new `##` group only when three or more pages justify it; otherwise use `## General`. Rewrite a page's summary whenever its scope changes, and drop `**Stub.**` when the `stub` tag goes. After every write, verify the index matches the directory listing exactly.

---

## 7. Maintenance Operations

**Rename a note:** create the new file, move the content, update every inbound wikilink across the vault (search for the old name first), delete the old file, update `INDEX.md`, log as `Renamed`.

**Merge duplicates:** pick the richer page as the survivor, merge content per §1.3, repoint all inbound links to the survivor, delete the loser (ask first), update `INDEX.md`, log as `Merged`.

**Delete a note:** ask the user first. Then repoint or remove all inbound links, delete the file, remove it from `INDEX.md`, and log as `Deleted` with the reason.

**Lint pass:** when asked to audit the vault, run **both** checklists in §9 across all notes — structural *and* semantic — and report findings before making any fixes. Log the pass as `Audited` with a one-line count of each defect class found. A lint pass that reports only structural defects is incomplete.

---

## 8. Skill Routing

Skills are reusable procedures stored as plain markdown under `.skill/`. Nothing loads them
automatically — when a trigger below applies, **read the `SKILL.md` before acting**, and read its
reference files when the skill tells you to. Skills elaborate on this constitution; they never
override it (see Precedence).

| Skill                                                    | What it covers                                                                                                | Read it when                                                                                                                             |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| [`obsidian-markdown`](.skill/obsidian-markdown/SKILL.md) | Obsidian Flavored Markdown: wikilinks, embeds, callouts, frontmatter properties, comments, and block references | Writing or editing any note body; the user mentions wikilinks, callouts, embeds, or frontmatter; a link or embed is not rendering right   |
| [`tag-taxonomy`](.skill/tag-taxonomy/SKILL.md)           | The six tag facets (`domain`, `topic`, `concept`, `tech`, `type`, `lifecycle`), their controlled vocabularies, banned tags, and the tag audit workflow | **Every time you assign or change a tag**; the user says "fix my tags", "normalize tags", "tag audit", "retag", "my tags are a mess", or asks what tags to use, how notes are classified, or how to add one |

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

## 9. Definition of Done

### Structural checks

Mechanical, verifiable by inspection. Run on every write, and across all notes in a lint pass.

- [ ] Every touched note has all four required frontmatter fields, and `updated` reflects the real current time.
- [ ] Every touched note has an H1 matching `title` and a `## Related Concepts` section.
- [ ] Every wikilink resolves to a file that exists; none are broken or unpiped.
- [ ] New notes are reachable from at least one existing note.
- [ ] `wiki/INDEX.md` lists exactly the files present in `wiki/concepts/`, each with a current one-line summary.
- [ ] `wiki/log.md` has one entry per logical action, timestamped from the real clock and carrying its `ingest`/`query`/`lint`/`maintain` operation field — including `Answered` and `Audited` actions, not only writes. No past entry was edited or reformatted.
- [ ] Every ingested source is recorded in the note's `sources` frontmatter and is still present in `raw/processed/`.
- [ ] Successfully ingested sources were moved to `raw/processed/`; failed ones remain in `raw/`.
- [ ] Every `stub` tag is on a genuine placeholder; every `needs-review` tag has a matching non-empty `## Open Questions & Disagreements` section, and vice versa.
- [ ] No duplicate concept pages were introduced.
- [ ] Every skill touched under `.skill/` has a matching, current row in the §8 routing table.

### Semantic checks

Judgement-based. Required in a lint pass; apply to touched pages on every write. Report these as
findings with a proposed fix — never silently "correct" them.

- [ ] **Contradictions.** No two pages assert incompatible claims. Where they do, both are named under `## Open Questions & Disagreements` rather than left to be discovered.
- [ ] **Stale claims.** Nothing is superseded by a newer source, a newer software version, or a changed price or API without being updated or dated.
- [ ] **Orphans and weak links.** No page has zero inbound links; no two pages that clearly relate fail to link each other.
- [ ] **Missing pages.** Concepts named repeatedly in prose across several notes have their own page, not just a bolded phrase.
- [ ] **Hollow hubs.** No heavily inbound-linked page is still a `stub`. The most-referenced pages should be the richest, not the thinnest.
- [ ] **Unsourced claims.** Specific figures, version numbers, and quotations trace to a `sources` entry or an inline citation.
- [ ] **Next questions.** The pass ends with a short list of questions worth investigating and gaps a new source or web search could close.

---

## References

- Andrej Karpathy's `llm-wiki` gist: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
