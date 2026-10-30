---
name: wiki-audit-trail
description: Exact formats for `wiki/log.md` entries and `wiki/INDEX.md`. Read before writing any log entry or editing INDEX.md, i.e. on every wiki create, update, rename, merge, delete, ingest, answered query, or lint pass.
user-invocable: false
---

# Wiki Audit Trail

Formats for the two audit files; the invariants are `AGENTS.md` §1.5 and §6.

## `wiki/log.md`

Newest entry first, immediately under the `# Activity Log` heading, one line per request:

```markdown
- **YYYY-MM-DD HH:mm:ss** · <operation> · <Verb> `[[concepts/<folder>/note_name]]` — <the headline change and why>. Source: `raw/processed/<file>`.
```

- **Timestamp:** date *and* time from the request's clock reading, so same-day entries stay ordered.
- **Operation:** exactly one of `ingest`, `query`, `lint`, or `maintain`, matching the workflow. The
  `·` separators keep the log greppable: `grep ' · lint · ' wiki/log.md`.
- **Verb:** `Created`, `Updated`, `Expanded`, `Merged`, `Renamed`, `Deleted`, `Answered` (query),
  or `Audited` (lint pass).
- Omit the `Source:` clause for direct requests.

**Writing it: never read the whole log.** Read only its first 3 lines (Read with `limit: 3`, or
`head -n 3 wiki/log.md`), then insert the entry plus one blank line directly under
`# Activity Log`. To look something up in the log, grep it. `git diff -U0 wiki/log.md` must show
only added lines.

**What gets an entry:** every change under `wiki/` (an asset under `raw/assets/` is a clause of the
entry for the note that embeds it), plus every `query` and every `lint` pass, even when nothing
changed. Nothing else (`AGENTS.md` §1.5).

### Keep entries short

An entry points to a change; it never copies it. One sentence, about 40 words at most.

- Log **what changed, where, and why**, never what the note now says.
- **Fold routine companion edits in:** the INDEX entry, backlinks, `updated`, `sources`, archiving
  the raw file, the `wiki/hot.md` route. Mention one only when it was unusual (a new index group, links repointed
  vault-wide).
- A judgement call or deviation gets **one clause**; anything longer belongs under the note's
  `## Open Questions & Disagreements`.

```markdown
- **2026-10-22 13:14:46** · maintain · Created `[[concepts/data_governance/data_sanity_check]]` — cheap assertions that prove data is not obviously broken, distinguished from full validation. Two open questions recorded; tagged `needs-review`.
```

A `query` entry names the question, the pages read, and what was filed:

```markdown
- **YYYY-MM-DD HH:mm:ss** · query · Answered "<question>". Read: `[[concepts/<folder>/a]]`, `[[concepts/<folder>/b]]`. Filed: <new page / section / stub / open question / nothing, and why>.
```

A lint pass writes `lint · Audited N notes — <one count per defect class>`; applying the approved
fixes afterwards is its own request with its own `maintain · Updated` entry.

Older entries use a date-only `- **YYYY-MM-DD**:` prefix, run long, or log `AGENTS.md` and
`.skill/` changes. That is the expected state; never touch them (`AGENTS.md` §6).

## `wiki/INDEX.md`

Exactly the pages in `wiki/concepts/`, mirroring the folder tree: one `##` group per domain folder
and one `###` subgroup per subfolder, each with a `Folder:` line. Groups sort as the folders
do; pages are alphabetized within a group (a hub may come first) and use piped wikilinks.

**Every entry has a one-line summary** after an em dash, so an agent can shortlist from the index
alone: at most ~160 characters, naming the sub-topics rather than restating the content, and
keeping acronyms and product names. Append `**Stub.**` for a page tagged `stub`.

```markdown
## Data Governance

Folder: `wiki/concepts/data_governance/`

- [[concepts/data_governance/data_quality|Data Quality]] — the six dimensions and their checks, where defects originate, and the measure-remediate lifecycle.
```

To edit one entry without reading the whole index, `grep -n '^##' wiki/INDEX.md` and Read only
that group's lines. Rewrite a summary when the page's scope changes; drop `**Stub.**` when the
`stub` tag goes. After every write the index must match the tree (empty output):

```bash
diff <(find wiki/concepts -name '*.md' | sed 's|^wiki/||; s|\.md$||' | sort) \
     <(grep -o '\[\[concepts/[^|]*' wiki/INDEX.md | sed 's|^\[\[||' | sort)
```
