---
name: wiki-lint
description: Run a whole-vault lint pass over `wiki/` — the structural checks (frontmatter, H1, wikilinks, INDEX.md vs. the folder tree, sources, lifecycle tags, the skill registry) and the semantic checks (contradictions, stale claims, orphans and weak links, missing pages, hollow hubs, unsourced claims, next questions) from AGENTS.md §9 — then report, apply only approved fixes, log, and re-verify. Use this skill whenever the user says "lint the vault", "lint pass", "audit the wiki", "health check", "check the vault", "find broken links", "find orphans", "find duplicates", "what's stale", or asks whether the wiki is consistent. It also owns the Obsidian syntax rules every note body must follow (`references/obsidian-syntax.md`: piped full-path wikilinks, callouts, `raw/assets/` embeds, Mermaid, math, and the banned Obsidian features), which wiki-create and wiki-ingest read when writing; read that file when the user says "check Obsidian syntax" or asks whether a note renders in Obsidian. For a tags-only audit, use tag-taxonomy's references/audit.md instead; this skill calls into it for the tag checks.
---

# Wiki Lint

A lint pass audits every note under `wiki/concepts/` against the two checklists in `AGENTS.md` §9
— **structural** and **semantic** — and reports what it finds before changing anything. §9 is the
canonical list of checks; this skill is the procedure for running them. Tag checks are delegated to
[`tag-taxonomy/references/audit.md`](../tag-taxonomy/references/audit.md) rather than repeated here.
The Obsidian syntax rules, which writers also follow, live in
[obsidian-syntax.md](references/obsidian-syntax.md).

This skill operates under `AGENTS.md`, which wins on conflict.

## Ground Rules

1. **Report before writing.** A lint pass edits nothing until the user has seen the findings and
   approved the fixes. A pass that reports only structural defects is incomplete (`AGENTS.md` §7).
2. **Approval thresholds.** Fixes touching more than ~10 notes, any merge, and any delete need
   explicit approval (`AGENTS.md` §1, Prohibited).
3. **Semantic findings are proposals.** Never silently "correct" a contradiction, a stale claim, or
   a missing page. Report it with a proposed fix.
4. **Respect hand edits.** If the log or git history shows the user deliberately left something in
   a non-conforming state, flag it in one line and leave it.
5. **Never touch history.** Old `wiki/log.md` entries with date-only prefixes or long bodies are
   the expected state, not defects ([`wiki-audit-trail`](../wiki-audit-trail/SKILL.md)).

## 1. Collect

Build the inventory with read-only commands. Every later check runs against it.

```bash
# Every note, with its folder
find wiki/concepts -name '*.md' | sort

# Frontmatter of every note (title, tags, sources, created, updated)
find wiki/concepts -name '*.md' -exec head -n 8 {} +

# Every wikilink, one per line: file:[[target|text]]
grep -rno '\[\[[^]]*\]\]' wiki/ --include='*.md'

# Index entries
grep -n '^\(##\|###\|Folder:\|- \[\[\)' wiki/INDEX.md

# Leftover intake and the skill registry
find raw -maxdepth 1 -type f
ls .skill/*/SKILL.md
```

From the wikilink list, compute **outbound** and **inbound** counts per note. Links from
`INDEX.md` do not count toward inbound reachability; links from `wiki/log.md` count for nothing.

## 2. Structural Checks

Each failure is a **defect** (propose a fix) or a **flag** (report for the user to judge).

| §9 item | How to test | Kind |
| --- | --- | --- |
| Required frontmatter | `title`, `tags`, `created`, `updated` all present; timestamps match `YYYY-MM-DD HH:mm:ss`; `tags` and `sources` are inline lists | Defect |
| H1 and Related Concepts | First `# ` heading equals `title`; a `## Related Concepts` section exists; no skipped heading levels | Defect |
| Tags | Run [audit.md](../tag-taxonomy/references/audit.md) steps 1–3 and merge its defects and flags into this report | Per audit.md |
| Wikilinks resolve | Each `[[target\|text]]` target + `.md` exists under `wiki/`, and a `#Heading` target matches a heading in that file | Defect |
| Obsidian syntax | Run the [obsidian-syntax.md](references/obsidian-syntax.md) Checks greps (unpiped or short-path links, banned syntax, extra properties); drop hits inside code fences | Defect |
| Reachability | Every note has ≥1 outbound link and ≥1 inbound link from another note | Defect |
| INDEX matches the tree | Two-way diff of index entries vs. `find` output; one `##` group per domain folder and `###` per tech subfolder, each with a correct `Folder:` line; pages alphabetized (hub first allowed); every entry has a summary; `**Stub.**` present exactly on `stub`-tagged pages | Defect |
| Sources | Every `raw/processed/…` path in `sources` exists | Defect |
| Intake queue | Files sitting in `raw/` outside `processed/` and `assets/` | Flag (pending ingest) |
| Lifecycle tags | `needs-review` ⇔ non-empty `## Open Questions & Disagreements`; `stub` only on placeholders | Defect, or flag if a hand edit |
| Duplicates | Two notes whose titles, acronyms, or definition paragraphs describe the same concept | Flag (merge needs approval, §7) |
| Skill registry | Every `.skill/*/SKILL.md` has exactly one `AGENTS.md` §8 row, every row's link exists, and no row describes old behaviour | Defect |

## 3. Semantic Checks

These are judgement calls. Read the notes involved in full before reporting one.

| §9 item | Method |
| --- | --- |
| Contradictions | Group notes that share a `topic` or `concept` tag, or link each other, and compare their definitions, figures, and recommendations. A conflict already recorded under `## Open Questions & Disagreements` is not a new finding. |
| Stale claims | Grep for version numbers, years, prices, and words like `currently`, `latest`, `new`, `deprecated`. Flag anything time-sensitive that is undated or older than its `sources`. |
| Orphans and weak links | Notes with inbound count 0. Pairs of notes that share two or more `topic`/`concept` tags but do not link each other. |
| Missing pages | Bolded or unlinked terms that appear across three or more notes with no page of their own. |
| Hollow hubs | `stub` notes ranked by inbound count. A heavily linked stub is a priority to expand. |
| Unsourced claims | Specific figures, version numbers, and quotations on notes with no matching `sources` entry or inline citation. |
| Next questions | Gaps a new source or web search could close. Always end the report with these. |

## 4. Report

Present, in this order, then **stop and wait for approval**:

1. **Counts** — one line per defect class, e.g. `3 broken links · 1 orphan · 2 index mismatches`.
2. **Defects** — a table: `file → check → proposed fix`.
3. **Flags** — each with a one-line reason.
4. **Semantic findings** — each with the notes involved and a proposed fix.
5. **Next questions** — a short list.

## 5. Apply

Only approved fixes. Read the clock once and reuse it for every `updated` and the log entry.

| Fix | Procedure |
| --- | --- |
| Tag change | `audit.md` §5 |
| Domain change or file move | Rename, `AGENTS.md` §7 |
| Duplicate pages | Merge, `AGENTS.md` §7 (ask before deleting the loser) |
| Contradiction | Record both positions under `## Open Questions & Disagreements`, tag `needs-review` (`AGENTS.md` §3) |
| Missing page or hollow hub | Create a `stub` or expand the page per `AGENTS.md` §3, linked both ways |
| Broken link, orphan, index drift | Edit the link, add a backlink, rewrite the index entry |
| Obsidian syntax defect | Rewrite it per [obsidian-syntax.md](references/obsidian-syntax.md) |
| Skill registry drift | Edit the §8 row (no log entry; outside `wiki/`) |

## 6. Log

One `wiki/log.md` entry for the whole pass, kept to a headline line of about 40 words ([`wiki-audit-trail`](../wiki-audit-trail/SKILL.md)):

```markdown
- **YYYY-MM-DD HH:mm:ss** · lint · Audited 44 notes — 3 broken links, 1 orphan, 2 index mismatches, 1 contradiction, 4 next questions. No fixes applied.
- **YYYY-MM-DD HH:mm:ss** · maintain · Updated 6 notes — fixed the 3 broken links and 2 index mismatches from the lint pass above; backlinked the orphan.
```

A report-only pass gets the `lint` entry alone. When fixes are applied, add one `maintain` entry
for them. A pass whose only fix is outside `wiki/` (for example the §8 table) adds no `maintain`
entry.

## 7. Verify

Re-run step 1 and every check that produced a fixed defect. Confirm each fix **in the file
itself**, not in your report. A past pass logged a banned tag as removed when the note still had
it. Then confirm `INDEX.md` matches the recursive listing of `wiki/concepts/` exactly.

## Definition of Done

- [ ] Every note in `wiki/concepts/` was checked against both §9 checklists, with tags via `audit.md`.
- [ ] The report gave counts, defects, flags, semantic findings, and next questions before any edit.
- [ ] Only approved fixes were applied, each through its `AGENTS.md` procedure, from one clock reading.
- [ ] `wiki/log.md` has one `lint · Audited` entry, plus one `maintain` entry only if wiki fixes were applied; no past entry was edited.
- [ ] Re-verification found every fixed defect gone in the files, and `INDEX.md` matches the tree.
