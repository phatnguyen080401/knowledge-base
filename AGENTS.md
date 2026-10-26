# Knowledge Base Agent Instructions

**This file is the canonical, non-negotiable constitution for every AI agent operating in this repository.** It defines the vault's structure, the required formats, and the exact procedures for reading and writing knowledge. There are no external scripts or plugins — the entire system's logic is encoded here.

The architecture is inspired by Andrej Karpathy's `llm-wiki` concept and the "AI Second Brain" pattern.

**Precedence:** `AGENTS.md` > any other instruction file in this repo (`GEMINI.md`, `.github/copilot-instructions.md`, etc.) > agent defaults. Other instruction files may only point to this one; they must not contradict it. If a user request conflicts with a rule here, say so and ask before proceeding.

**Skills:** detailed procedures live in `.skill/`. They are not auto-loaded — you must read them yourself. See §8 for the routing table.

### Quick path — what to read before you act

| Task                                   | Read, in order                                                                                                    |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Create or expand a note                | [`wiki-create`](.skill/wiki-create/SKILL.md) → [`tag-taxonomy`](.skill/tag-taxonomy/SKILL.md) + its `taxonomy.md` |
| Ingest from `raw/`                     | `wiki/INDEX.md` → search `wiki/concepts/` (§4.4) → `tag-taxonomy` + its `taxonomy.md`                             |
| Answer a question                      | `wiki/INDEX.md` first, then the shortlisted pages (§5)                                                            |
| Retag or tag audit                     | `tag-taxonomy` SKILL + `references/taxonomy.md` + `references/audit.md`                                          |
| Lint pass or vault audit               | §9 → [`wiki-lint`](.skill/wiki-lint/SKILL.md) → `tag-taxonomy` `references/audit.md` for the tag checks           |
| Commit                                 | [`git-commit-helper`](.skill/git-commit-helper/SKILL.md)                                                          |

**One clock reading per request.** Read the system clock once at write time and reuse that value
for every `created`/`updated` you set and for the `wiki/log.md` timestamp. The entry then matches
the notes it describes. Bash: `date +"%Y-%m-%d %H:%M:%S"`; PowerShell:
`Get-Date -Format "yyyy-MM-dd HH:mm:ss"`. Never invent or copy a timestamp.

---

## 1. Mandatory Rules

**These rules are absolute.**

1. **Markdown native.** Every operation is a read or write of a markdown file. Never introduce build scripts, databases, or plugin dependencies.
2. **Agent-driven.** You are the runtime. The file system is the only state. Read the vault to learn its state; write to the vault to change it.
3. **Compile, don't retrieve.** The wiki is pre-compiled knowledge, not an archive of clippings. Merge new information into the existing page. Never append a redundant section, never create a near-duplicate page, never paste raw source text verbatim.
4. **Atomic, complete transactions.** A task is finished only when the note, its wikilinks, `wiki/INDEX.md`, and `wiki/log.md` are all consistent. Never leave the audit trail half-updated.
5. **Every write under `wiki/` is audited — and only those.** Any create, update, rename, or delete under `wiki/` MUST produce a `wiki/log.md` entry and a correct `wiki/INDEX.md`. The log's scope is the `wiki/` folder and nothing else: a change to `AGENTS.md`, to anything under `.skill/`, or to any other file outside `wiki/` gets **no log entry**. When such a change accompanies a wiki change, name it in one clause of that entry instead of giving it its own.
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
│   ├── assets/                # Images, PDFs, and other binaries linked from notes
│   └── processed/             # Archive of successfully ingested source files
└── wiki/                      # The compiled knowledge base
    ├── INDEX.md               # Master index of every wiki page, grouped by folder
    ├── log.md                 # Reverse-chronological activity log
    └── concepts/              # Atomic notes — one file per concept, filed by domain
        ├── ai_engineering/
        ├── data_architecture/
        ├── data_engineering/
        │   ├── dbt/
        │   ├── kafka/
        │   └── spark/
        ├── data_governance/
        ├── data_structures/
        ├── databases/
        ├── devops/
        ├── software_architecture/
        └── version_control/
            └── gitlab/
```

This tree is a snapshot. The authoritative list of domain folders is the `domain` table in
[`.skill/tag-taxonomy/references/taxonomy.md`](.skill/tag-taxonomy/references/taxonomy.md), which
maps every domain tag to its folder.

**Filing a note into a folder**

Every note lives in the folder of its `domain` tag — `databases` → `concepts/databases/`,
`software-architecture` → `concepts/software_architecture/`. The folder and the tag must always
agree. Changing a note's domain tag means moving the file, which is a rename (§7). A note never sits
loose at the root of `concepts/`.

A **tech subfolder** one level deeper clusters a product family that has its own namesake hub note,
for example `data_engineering/dbt/` with `dbt.md`. Every note inside carries that product's `tech` tag.
Never nest deeper than one level. A new *domain* folder requires a new `domain` tag, which needs
user approval (§1, Prohibited).

**Naming conventions**

| Item                | Rule                                                                         | Example                                   |
| ------------------- | ---------------------------------------------------------------------------- | ----------------------------------------- |
| Folder name         | `snake_case` of the note's `domain` tag; one level of tech subfolder allowed | `databases/`, `data_engineering/dbt/`     |
| Concept filename    | `snake_case.md`, singular, no dates, no numbering                            | `master_data_management.md`               |
| `title` frontmatter | Title Case, human-readable, may include an acronym                           | `Master Data Management (MDM)`            |
| Asset filename      | `snake_case` with extension, prefixed by related concept                     | `data_quality_dimensions.png`             |
| Wikilink            | `[[concepts/<folder>/file_name\|Display Text]]` — always the full vault-relative path, always piped | `[[concepts/data_governance/data_quality\|Data Quality]]` |

---

## 3. Note Format

Every file in `wiki/concepts/` follows this shape:

```markdown
---
title: Data Quality
tags: [data-governance, data-quality, data-validation]
sources: [raw/processed/dama_dmbok_ch11.md, "https://example.org/article"]
created: 2026-09-22 09:11:46
updated: 2026-09-23 10:25:15
---

# Data Quality

One- or two-sentence definition or high-level summary of what this note contains that stands alone, linking the parent concept
such as [[concepts/data_governance/data_governance|Data Governance]].

## Why It Matters

## <Topic-specific sections>

## Open Questions & Disagreements

- <Claim A> (source X) conflicts with <claim B> (source Y). Unresolved because …

## Related Concepts

- [[concepts/data_governance/data_stewardship|Data Stewardship]] — who is accountable for quality
- [[concepts/data_governance/metadata_management|Metadata Management]] — where quality rules are documented
  
## References
- Additional outside URLs or citations go here.
```

**Frontmatter rules**

- `title` — string; must match the note's H1 heading.
- `tags` — chosen with the [`tag-taxonomy`](.skill/tag-taxonomy/SKILL.md) skill. At minimum: one `domain` tag (which must match the folder), 1–3 `topic` tags, and for a substantive note at least one `concept` or `tech` tag. At most 10 tags in facet order. Add `stub` while the note is a placeholder and **remove it** once the note is substantive.
- **List form.** `tags` and `sources` are always inline YAML lists on one line (`tags: [a, b]`), never block lists with `- item` lines.
- `sources` — optional YAML inline list. Every `raw/processed/<file>` path and external URL that contributed a fact to this page. **Append on every ingest; never remove an entry** — this is the provenance trail that makes §1.9 auditable after the fact. Quote bare URLs. A note with no `sources` rests on well-established general knowledge or direct user input.
- `created` — `YYYY-MM-DD HH:mm:ss`. Set once, never changed.
- `updated` — `YYYY-MM-DD HH:mm:ss`. Set on every content change.
- Timestamps must come from the real system clock: bash `date +"%Y-%m-%d %H:%M:%S"`, PowerShell `Get-Date -Format "yyyy-MM-dd HH:mm:ss"`. Never invent or copy a timestamp.

**Body rules**

- Start with an H1 matching `title`, then a standalone definition paragraph.
- Use `##` for sections; do not skip heading levels.
- Prose and bullets only. No raw HTML. Code fences only for actual code, config, or queries.
- Link the first meaningful mention of another concept; do not re-link the same concept in every paragraph.
- Include `## Open Questions & Disagreements` whenever sources conflict, a claim is unverified, or you had to extrapolate. Name both positions and their sources; never silently pick a winner. Tag the note `needs-review` while the section is non-empty, and delete the section once everything in it is resolved.
- End with a `## Related Concepts` section that explains *why* each link matters, not just a bare list.
- Cite non-obvious external sources inline (`[Title](url)`) or in a final `## References` section, placed after `## Related Concepts`.

---

## 4. Workflow: Ingesting from `raw/`

1. **Scan.** List `raw/`, excluding `raw/processed/` and `raw/assets/`. If empty, report that and stop.
2. **Read the source.** Read the file in full before deciding anything. Move binaries to `raw/assets/` and describe what they depict.
3. **Identify concepts.** One raw file may contain several concepts — split it, one concept per note. Never create a note that merely mirrors the source document's shape.
4. **Search before writing.** Search `wiki/concepts/` by filename *and* by content (synonyms, acronyms, plurals), and check `wiki/INDEX.md`.
   - Match found → **Update**.
   - No match → **Create**.
   - Ambiguous or partially overlapping → ask the user; never create a near-duplicate.
5. **Write.**
   - **Create:** a new file per §3, filled in as far as the source supports.
   - **Update:** merge into the correct existing section. Rewrite sentences to integrate the new facts; do not bolt on an "Update" or "Additional Notes" section. Bump `updated`.
   - **Conflict:** if new information contradicts the page, do not silently overwrite. Keep the better-sourced claim in the body, **and record both positions with their sources under `## Open Questions & Disagreements`** — a conflict raised only in your chat summary is a conflict that will be forgotten. Add `needs-review` to `tags`.
   - **Tag and file:** choose or re-check the tags with the `tag-taxonomy` skill on every create or update. The `domain` tag decides the folder; a note in a tech subfolder carries that product's `tech` tag.
6. **Link both ways.** Add outbound wikilinks from the new or changed note, **and** add a link back from at least one related existing note so the page is reachable.
7. **Archive the source.** Move the raw file to `raw/processed/` **only after** steps 5–6 succeed. If ingestion fails or is aborted, leave it in `raw/` so it is retried.
8. **Update the audit trail.** Append **one** `wiki/log.md` entry for the request and update `wiki/INDEX.md` (see §6), and append each ingested source to the note's `sources` frontmatter. Mandatory, and always last.
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
   filed — including `Filed: nothing` when that was the right call. Do not restate the answer in
   the log. The log covers all three operations, not only ingestion.

**Never** answer a vault question purely from memory without reading the pages, and never let a
question that produced something worth keeping leave the vault unchanged.

---

## 6. Audit Trail

### `wiki/log.md`

Append-only, newest entry first, immediately under the `# Activity Log` heading. **One entry per request**, on one line:

```markdown
- **YYYY-MM-DD HH:mm:ss** · <operation> · <Verb> `[[concepts/<folder>/note_name]]` — <the headline change and why>. Source: `raw/processed/<file>`.
```

- **Timestamp** — full date *and* time, from the real system clock (the same reading used for the notes' `updated`; see the Quick path), so the log records *when* the vault changed and entries written on the same day stay ordered. Never invent or copy a timestamp.
- **Operation** — exactly one of `ingest`, `query`, `lint`, or `maintain`, matching the workflow that produced the entry. The `·` separators make the log greppable by operation: `grep ' · lint · ' wiki/log.md`.
- **Verb** — `Created`, `Updated`, `Expanded`, `Merged`, `Renamed`, `Deleted`, `Answered` (§5), or `Audited` (§7 lint pass).
- Omit the `Source:` clause for direct requests.

#### What gets logged

The log is the audit trail of **the `wiki/` folder**, not of the repository. Per §1.5, write an entry when, and only when, a request changed something under `wiki/` — the sole exception being the `query` entry §5.6 requires, which records a question answered *from* the wiki even when nothing was filed.

| Change                                                                | Log entry? |
| --------------------------------------------------------------------- | ---------- |
| Any note under `wiki/concepts/`, or `wiki/INDEX.md`                   | Yes        |
| An asset under `raw/assets/` — only as a clause of the note entry that links it | Folded in |
| A question answered from the vault (§5), including `Filed: nothing`   | Yes        |
| `AGENTS.md` — a rule, workflow, or routing-table change               | No         |
| Anything under `.skill/` — a new skill, a reworded procedure, a vocabulary addition | No |
| Repository plumbing — `.gitignore`, `README.md`, CI config, tooling   | No         |

A change outside `wiki/` that lands *alongside* a wiki change is not a separate entry and not a separate line: fold it into the one entry as a trailing clause, and only when it explains the wiki change. A request that touched nothing under `wiki/` leaves the log untouched — the git history is the record for those files.

Entries written before this rule took effect log `AGENTS.md` and `.skill/` changes. The log is append-only, so they stay exactly as written.

#### Keep entries short

An entry is a **pointer to a change, not a copy of it**. The content lives in the note, which is where it is read; restating it here doubles the writing and ages badly the moment the note is edited. One sentence, ceiling about 40 words. If an entry needs a paragraph, the detail belongs in the note.

- Log **what changed, where, and why** — never *what the note now says*. A section-by-section tour of the tables, callouts, and arguments a note contains is the note, pasted twice.
- **Fold routine companion edits in.** Updating `INDEX.md`, adding backlinks, bumping `updated`, appending `sources`, and archiving the raw file are required by §4 on every write — they are not news and never get their own entry. Mention one only when it was unusual (a new index group, links repointed vault-wide).
- **Split only for genuinely separate actions** — two unrelated notes changed in one request. Not for each file a single change touched, and never for a file outside `wiki/`.
- Record a judgement call or deviation in **one clause**. Anything longer belongs under `## Open Questions & Disagreements` in the note, where it will actually be found.

```markdown
Good: - **2026-10-22 13:14:46** · maintain · Created `[[concepts/data_governance/data_sanity_check]]` — cheap assertions that prove data is not obviously broken, distinguished from full validation. Two open questions recorded; tagged `needs-review`.

Bad:  the same entry listing every section, table, threshold, and pitfall the note contains.
```

A `query` entry names the question, the pages read, and what was filed:

```markdown
- **YYYY-MM-DD HH:mm:ss** · query · Answered "<question>". Read: `[[concepts/<folder>/a]]`, `[[concepts/<folder>/b]]`. Filed: <new page / section / stub / open question / nothing, and why>.
```

**The log is append-only.** Never edit, reorder, reformat, or condense a past entry; only correct a factual typo. Earlier entries use a date-only `- **YYYY-MM-DD**:` prefix or run far longer than the ceiling above; both are left exactly as written. The mixed format is the expected state, not a defect to clean up.

### `wiki/INDEX.md`

The complete list of every page in `wiki/concepts/` — no more, no less. **The index mirrors the
folder tree:** one `##` group per domain folder, one `###` subgroup per tech subfolder, each
carrying a `Folder:` line with its path. Groups are ordered as the folders sort; pages are
alphabetized within each group, and use piped wikilinks. **Every entry carries a one-line summary**
after an em dash, written so the agent can shortlist from the index alone without opening files
(§5.1). Append `**Stub.**` to the summary of any page tagged `stub`. A hub page may be listed first
in its group, ahead of alphabetical order:

```markdown
# Index

## Data Governance

Folder: `wiki/concepts/data_governance/`

- [[concepts/data_governance/data_quality|Data Quality]] — the six dimensions and their checks, where defects originate, and the measure-remediate lifecycle.
```

Each page belongs to exactly one group, and that group is the folder it is in — the index can never
disagree with the directory tree. Rewrite a page's summary whenever its scope changes, and drop
`**Stub.**` when the `stub` tag goes. After every write, verify the index matches the recursive
directory listing exactly.

---

## 7. Maintenance Operations

**Rename a note:** create the new file, move the content, update every inbound wikilink across the vault (search for the old name first), delete the old file, update `INDEX.md`, log as `Renamed`.

**Merge duplicates:** pick the richer page as the survivor, merge content per §1.3, repoint all inbound links to the survivor, delete the loser (ask first), update `INDEX.md`, log as `Merged`.

**Delete a note:** ask the user first. Then repoint or remove all inbound links, delete the file, remove it from `INDEX.md`, and log as `Deleted` with the reason.

**Lint pass:** when asked to audit the vault, follow the [`wiki-lint`](.skill/wiki-lint/SKILL.md) skill and run **both** checklists in §9 across all notes — structural *and* semantic — and report findings before making any fixes. Log the pass as `Audited` with a one-line count of each defect class found. A lint pass that reports only structural defects is incomplete.

---

## 8. Skill Routing

Skills are reusable procedures stored as plain markdown under `.skill/`. Nothing loads them
automatically — when a trigger below applies, **read the `SKILL.md` before acting**, and read its
reference files when the skill tells you to. Skills elaborate on this constitution; they never
override it (see Precedence).

| Skill                                                    | What it covers                                                                                                | Read it when                                                                                                                             |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| [`git-commit-helper`](.skill/git-commit-helper/SKILL.md) | Generating short Conventional Commits 1.0.0 messages from the diff: type and scope selection, breaking-change signalling, when a body is earned and how short it stays, splitting a tree, amending a message | Running or being asked to run `git commit`; staging changes; the user asks for a commit message, whether a change is a `feat` or a `fix`, or to fix or amend an existing message |
| [`tag-taxonomy`](.skill/tag-taxonomy/SKILL.md)           | The six tag facets (`domain`, `topic`, `concept`, `tech`, `type`, `lifecycle`), their controlled vocabularies, the domain → folder map, banned and retired tags, adding or retiring a tag, and the tag audit workflow (`references/audit.md`) | **Every time you create, update, move, or file a note**, or assign or change a tag; the user says "fix my tags", "normalize tags", "tag audit", "retag", "my tags are a mess", or asks what tags to use, how notes are classified, or how to add or retire one |
| [`wiki-create`](.skill/wiki-create/SKILL.md)             | Creating or expanding one concept note on a direct request: searching for duplicates, tags and folder, the §3 note shape, linking both ways, INDEX and log, verification | The user says "create a note on X", "new page for X", "add a note about X", "write up X", "expand the note on X", "stub out X", or runs `/wiki create`; not for files in `raw/` (use §4) |
| [`wiki-lint`](.skill/wiki-lint/SKILL.md)                 | The whole-vault lint pass: collecting an inventory, running the §9 structural and semantic checks (tags via `audit.md`), the report format, applying approved fixes, logging, and re-verifying | The user says "lint the vault", "lint pass", "audit the wiki", "health check", "find broken links", "find orphans", "find duplicates", "what's stale", or asks whether the wiki is consistent |

**Adding a skill:** create `.skill/<skill-name>/SKILL.md` with `name` and `description` frontmatter, put any long reference material in `.skill/<skill-name>/references/`, and add a row to the table above. A skill that is not listed here will not be found.

### Keeping this table in sync

This table is the skill registry, and it is maintained by you — there is no script (§1.1). Per §1.11, reconcile it **in the same action** that touches a skill:

| Trigger                                           | Required table change                                                                         |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------- |
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
- [ ] Every touched note's tags pass the `tag-taxonomy` Definition of Done: an inline list, a valid facet set, and a folder that matches the `domain` tag (plus the product's `tech` tag inside a tech subfolder).
- [ ] Every wikilink resolves to a file that exists; none are broken or unpiped.
- [ ] New notes are reachable from at least one existing note.
- [ ] `wiki/INDEX.md` lists exactly the files present in `wiki/concepts/`, each with a current one-line summary.
- [ ] `wiki/log.md` has one entry for the request — one headline line of about 40 words, no section-by-section restatement of the note, routine companion edits folded in — timestamped from the real clock and carrying its `ingest`/`query`/`lint`/`maintain` operation field. `Answered` and `Audited` actions are logged too, not only writes. A request that changed nothing under `wiki/` has **no** entry (§6, What gets logged). No past entry was edited or reformatted.
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
