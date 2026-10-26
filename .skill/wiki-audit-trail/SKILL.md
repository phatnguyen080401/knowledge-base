---
name: wiki-audit-trail
description: The formats for `wiki/log.md` and `wiki/INDEX.md` — the one-line log entry (timestamp, operation, verb, target, why, source), what does and does not get logged, keeping entries short, the `query` entry, append-only history, and the INDEX grouping, ordering, summaries, and `**Stub.**` marker. Read it before writing any `wiki/log.md` entry or editing `wiki/INDEX.md`, which means on every create, update, rename, merge, delete, ingest, answered question, or lint pass.
user-invocable: false
---

# Wiki Audit Trail

The format spec for the two audit files. `AGENTS.md` §6 holds the invariants; this skill holds the
exact shapes and examples.

This skill operates under `AGENTS.md`, which wins on conflict.

## `wiki/log.md`

Append-only, newest entry first, immediately under the `# Activity Log` heading. **One entry per
request**, on one line:

```markdown
- **YYYY-MM-DD HH:mm:ss** · <operation> · <Verb> `[[concepts/<folder>/note_name]]` — <the headline change and why>. Source: `raw/processed/<file>`.
```

- **Timestamp:** full date *and* time from the request's single clock reading, so entries written
  on the same day stay ordered. Never invent or copy a timestamp.
- **Operation:** exactly one of `ingest`, `query`, `lint`, or `maintain`, matching the workflow
  that produced the entry. The `·` separators make the log greppable: `grep ' · lint · ' wiki/log.md`.
- **Verb:** `Created`, `Updated`, `Expanded`, `Merged`, `Renamed`, `Deleted`, `Answered` (query),
  or `Audited` (lint pass).
- Omit the `Source:` clause for direct requests.

### What gets logged

The log is the audit trail of **the `wiki/` folder**, not of the repository. Write an entry when,
and only when, a request changed something under `wiki/`. The sole exception is the `query` entry,
which records a question answered *from* the wiki even when nothing was filed.

| Change                                                                              | Log entry? |
| ----------------------------------------------------------------------------------- | ---------- |
| Any note under `wiki/concepts/`, or `wiki/INDEX.md`                                 | Yes        |
| An asset under `raw/assets/`, only as a clause of the note entry that links it      | Folded in  |
| A question answered from the vault, including `Filed: nothing`                      | Yes        |
| `AGENTS.md`: a rule, workflow, or routing-table change                              | No         |
| Anything under `.skill/`: a new skill, a reworded procedure, a vocabulary addition  | No         |
| Repository plumbing: `.gitignore`, `README.md`, CI config, tooling                  | No         |

A change outside `wiki/` that lands *alongside* a wiki change is not a separate entry: fold it into
the one entry as a trailing clause, and only when it explains the wiki change. A request that
touched nothing under `wiki/` leaves the log untouched; git history is the record for those files.

### Keep entries short

An entry is a **pointer to a change, not a copy of it**. The content lives in the note; restating
it here doubles the writing and ages badly the moment the note is edited. One sentence, ceiling
about 40 words.

- Log **what changed, where, and why**, never *what the note now says*. A section-by-section tour
  of the note is the note, pasted twice.
- **Fold routine companion edits in.** Updating `INDEX.md`, adding backlinks, bumping `updated`,
  appending `sources`, and archiving the raw file happen on every write. They never get their own
  entry. Mention one only when it was unusual (a new index group, links repointed vault-wide).
- **Split only for genuinely separate actions**, such as two unrelated notes changed in one
  request. Not for each file a single change touched, and never for a file outside `wiki/`.
- Record a judgement call or deviation in **one clause**. Anything longer belongs under
  `## Open Questions & Disagreements` in the note.

```markdown
Good: - **2026-10-22 13:14:46** · maintain · Created `[[concepts/data_governance/data_sanity_check]]` — cheap assertions that prove data is not obviously broken, distinguished from full validation. Two open questions recorded; tagged `needs-review`.

Bad:  the same entry listing every section, table, threshold, and pitfall the note contains.
```

A `query` entry names the question, the pages read, and what was filed:

```markdown
- **YYYY-MM-DD HH:mm:ss** · query · Answered "<question>". Read: `[[concepts/<folder>/a]]`, `[[concepts/<folder>/b]]`. Filed: <new page / section / stub / open question / nothing, and why>.
```

### History is append-only

Never edit, reorder, reformat, or condense a past entry; only correct a factual typo. Earlier
entries use a date-only `- **YYYY-MM-DD**:` prefix, run far longer than the ceiling above, or log
`AGENTS.md` and `.skill/` changes from before the `wiki/`-only rule. All are left exactly as
written. The mixed format is the expected state, not a defect to clean up.

## `wiki/INDEX.md`

The complete list of every page in `wiki/concepts/`, no more and no less. **The index mirrors the
folder tree:** one `##` group per domain folder and one `###` subgroup per tech subfolder, each
carrying a `Folder:` line with its path. Groups are ordered as the folders sort; pages are
alphabetized within each group and use piped wikilinks. A hub page may be listed first in its
group.

**Every entry carries a one-line summary** after an em dash, written so an agent can shortlist from
the index alone without opening files. Append `**Stub.**` to the summary of any page tagged `stub`.

```markdown
# Index

## Data Governance

Folder: `wiki/concepts/data_governance/`

- [[concepts/data_governance/data_quality|Data Quality]] — the six dimensions and their checks, where defects originate, and the measure-remediate lifecycle.
```

Rewrite a page's summary whenever its scope changes, and drop `**Stub.**` when the `stub` tag goes.
After every write, verify the index matches the recursive directory listing exactly:

```bash
diff <(find wiki/concepts -name '*.md' | sed 's|^wiki/||; s|\.md$||' | sort) \
     <(grep -o '\[\[concepts/[^|]*' wiki/INDEX.md | sed 's|^\[\[||' | sort)
```
