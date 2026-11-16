---
name: wiki-lint
description: Run a whole-vault lint pass and apply the approved fixes. Use when the user says "lint the vault", "audit the wiki", "health check", "find broken links", "find orphans", "find duplicates", "what's stale", "check Obsidian syntax", or "apply the lint fixes", or asks whether the wiki is consistent or renders in Obsidian. Tags only → tag-taxonomy; researching stale or unsourced claims → wiki-resolve.
---

# Wiki Lint

The procedure for running the `AGENTS.md` §9 checks across every note in `wiki/concepts/`. Tag
checks are delegated to [audit.md](../tag-taxonomy/references/audit.md); body syntax is checked
against [obsidian-syntax.md](references/obsidian-syntax.md).

Report everything before changing anything; semantic findings are proposals. If the log or git
history shows the user deliberately left something non-conforming, flag it in one line and leave it.

## 1. Collect

Build the inventory with read-only commands. Every later check runs against it.

```bash
# Every note, with its folder
find wiki/concepts -name '*.md' | sort

# Frontmatter of every note (title, tags, sources, created, updated)
find wiki/concepts -name '*.md' -exec head -n 8 {} +

# Every link target, one per line: file:[[target[#Heading]  (a trailing \ is a table-cell pipe)
grep -ro '\[\[[^]|]*' wiki/concepts --include='*.md' | sed 's/\\$//' | sort -u

# Index entries, and the hot.md route targets
grep -n '^\(##\|###\|Folder:\|- \[\[\)' wiki/INDEX.md
grep -o '\[\[[^]|]*' wiki/hot.md | sort -u

# Leftover intake and the skill registry
find raw -maxdepth 1 -type f
ls .skill/*/SKILL.md
```

From the link list, compute **outbound** and **inbound** counts per note; only links between notes
count toward reachability. Re-grep with `-n` when you need a line number to fix a link. Never read
the whole `wiki/log.md`: check a hand edit with `grep -n '<file>' wiki/log.md` or `git log -- <note>`.

## 2. Structural Checks

Each failure is a **defect** (propose a fix) or a **flag** (report for the user to judge).

| §9 item | How to test | Kind |
| --- | --- | --- |
| Required frontmatter | `title`, `tags`, `created`, `updated` all present; timestamps match `YYYY-MM-DD HH:mm:ss`; `tags` and `sources` are inline lists | Defect |
| H1 and Related Concepts | First `# ` heading equals `title`; a `## Related Concepts` section exists; no skipped heading levels | Defect |
| Tags and lifecycle | Run [audit.md](../tag-taxonomy/references/audit.md) steps 1–3 and merge its defects and flags into this report | Per audit.md |
| Wikilinks resolve | Each target + `.md` exists under `wiki/`, and a `#Heading` target matches a heading in that file | Defect |
| Obsidian syntax | Run the [obsidian-syntax.md](references/obsidian-syntax.md) Checks greps on every note; drop hits inside code fences | Defect |
| Reachability | Every note has ≥1 outbound link and ≥1 inbound link from another note | Defect |
| INDEX matches the tree | The diff in [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md) is empty; groups, `Folder:` lines, ordering, summaries (≤ ~160 characters), and `**Stub.**` follow its INDEX spec | Defect |
| Query routes | Every `wiki/hot.md` link resolves, heading included; at most 40 one-line entries ([`wiki-query`](../wiki-query/SKILL.md)) | Defect |
| Sources | Every `raw/processed/…` path in `sources` exists; every URL in `sources` is the `Source:` line of one of those files, or sits beside an archived `.pdf` downloaded from it | Defect |
| Intake queue | Files sitting in `raw/` outside `processed/` and `assets/` | Flag (pending ingest) |
| Duplicates | Two notes whose titles, acronyms, or definition paragraphs describe the same concept | Flag (merge needs approval) |
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
| Unsourced claims | Specific figures, version numbers, and quotations on notes with no matching `sources` entry, `## References` bullet, or inline citation. |
| Bloated References | More than ~5 `## References` bullets, duplicates, or links nothing in the body relies on. Propose a trim; never delete silently. |
| Next questions | Gaps a new source or web search could close. Always end the report with these. |

## 4. Report

Present, in this order:

1. **Counts** — one line per defect class, e.g. `3 broken links · 1 orphan · 2 index mismatches`.
2. **Defects** — a table: `file → check → proposed fix`.
3. **Flags** — each with a one-line reason.
4. **Semantic findings** — each with the notes involved and a proposed fix.
5. **Next questions** — a short list.

Then read the clock and write the pass's one `lint · Audited N notes` log entry, one count per
defect class, ending `No fixes applied.` ([`wiki-audit-trail`](../wiki-audit-trail/SKILL.md)).
Only then **stop and wait for approval**.

## 5. Apply

Only approved fixes. Read the clock once (`AGENTS.md`) and reuse it.

| Fix | Procedure |
| --- | --- |
| Tag change | audit.md §5 |
| Domain change, file move, duplicate pages | [`wiki-maintain`](../wiki-maintain/SKILL.md) |
| Contradiction | Record both positions under `## Open Questions & Disagreements`, tag `needs-review` (`AGENTS.md` §3) |
| Missing page | Create a `stub` per `AGENTS.md` §3, linked both ways |
| Hollow hub, stale or unsourced claim, next question | [`wiki-resolve`](../wiki-resolve/SKILL.md) |
| Broken link, orphan, index drift | Edit the link, add a backlink, rewrite the index entry |
| Obsidian syntax defect | Rewrite it per obsidian-syntax.md |
| Skill registry drift | Edit the §8 row (outside `wiki/`, so no log entry) |

## 6. Log

Applying fixes is its own request: one `maintain · Updated N notes` entry naming what was fixed,
per [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md).

## 7. Verify

Re-run step 1 and every check that produced a fixed defect. Confirm each fix **in the file
itself**, not in your report: a report can say a fix landed while the file still has the
defect.

## Definition of Done

- [ ] Every note in `wiki/concepts/` was checked against both §9 checklists, with tags via audit.md.
- [ ] The report came before any edit, and only approved fixes were applied.
- [ ] `wiki/log.md` has the pass's `lint · Audited` entry, written with the report even when nothing was fixed.
- [ ] Re-verification found every fixed defect gone in the files.
