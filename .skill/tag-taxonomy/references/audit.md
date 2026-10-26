# Tag Audit / Normalization

Read this for a tag audit or when a wiki-lint pass reaches tags, after [SKILL.md](../SKILL.md) and
[taxonomy.md](taxonomy.md), whose rules are the standard. **Report before writing:** no note is
edited until the user has seen the findings and approved the changes.

## 1. Collect

Grep `^tags:` (with a few lines of context, to catch block lists) across `wiki/concepts/`. Record
each note's path, folder, and tags, and count each tag.

## 2. Classify every distinct tag

| Class | Test | Action |
| --- | --- | --- |
| **Approved** | In a closed-facet table, or a well-formed `tech` name | Leave it alone |
| **Retired** | In the Retired Tags table below | Rewrite it to its replacement; the decision is already made |
| **Banned** | In taxonomy.md's Banned table, or general enough to fit almost any note | Remove it, then check the note still has its mandatory set |
| **Typo** | A case, plural, separator, acronym, or vendor-prefix variant of an approved tag (`Data Quality`, `data_quality`, `db`, `google-bigquery`, `dbt-core`) | Rewrite it to the tag it obviously means |
| **Unknown** | None of the above | Propose a mapping and ask: it may be a deliberate user tag, a new `tech` name, or a vocabulary gap. Never delete it unilaterally |

### Retired Tags

Tags this vault once used and deliberately dropped. Each row is a real retirement traceable to a
`wiki/log.md` audit; a spelling variant is a Typo, never a row.

| Retired tag | Rewrite to | Retired because |
| --- | --- | --- |
| `algorithm`, `algorithms` | `indexing`, or drop | Implied by the `data-structures` domain; `indexing` only when the note is about lookup |
| `data-management` | `data-governance` | Merged — the vault files management disciplines under governance |
| `integration` | `api-protocols` on interface notes, `elt` on tooling notes | Ambiguous — conflated protocols, connectors, and ELT |
| `mdm` | `master-data` | Unexpanded acronym; the facet tables spell concepts out |
| `roles`, `stewardship` | `stewardship-roles` | Too broad alone; promoted to the `concept` facet with a sharper definition |
| `security` | `data-security` | Bare `security` reads as infrastructure security, not data security |

## 3. Check every note

Each check is a **defect**, which you propose to fix, or a **flag**, which you only report.

| Check | Kind |
| --- | --- |
| `tags` is a block list instead of an inline list | Defect |
| Missing a `domain` tag, missing a `topic`, or more than one `domain` | Defect |
| Substantive note with neither a `concept` nor a `tech` tag (`overview` exempt) | Defect |
| A technology named substantively in the body is absent from `tech` | Defect |
| Facets out of order, or more than 10 tags | Defect |
| Folder does not match the `domain` tag | Defect (the fix is a move, see §5) |
| A note in a tech subfolder lacks that subfolder's `tech` tag | Defect |
| `stub` on a substantive page | Defect |
| `needs-review` with no open questions, or open questions with no `needs-review` | Flag if the log or git history shows a user hand edit (`grep -n '<file>' wiki/log.md`, `git log -p -- <note>`; never read the whole log); otherwise defect |
| A tag that restates the note's own title (not `tech`) | Flag |
| `overview` on a note that does not route to child notes | Flag |
| A topic borrowed from another domain to fill a gap | Flag (candidate for a new topic) |
| A concept tag used by fewer than two notes | Flag (review only; never auto-remove) |
| A `tech` tag used by two or more notes with no seed-table row | Defect (add the row) |

## 4. Report

Show the user:

- a table: `file → current tags → proposed tags`
- the unknown tags and what you propose for each, marking the ones you believe are intentional
  user tags to keep
- the flags, each with a one-line reason
- any candidate new closed-facet tags, with their Covers/Excludes and the notes they would apply to

Then wait for approval.

## 5. Apply

- **Tag-only change:** rewrite the `tags` line, keeping the inline form, and set `updated` from the
  clock. Touch nothing else in the note; `wiki/INDEX.md` mirrors folders, not tags.
- **Domain change:** a move, via [`wiki-maintain`](../../wiki-maintain/SKILL.md).
- **Vocabulary change:** an approved new tag or seed row goes into [taxonomy.md](taxonomy.md).
- **Retiring a tag:** retag every affected note, then add a Retired row naming the replacement and
  the reason. That row is the only lasting record of *why*.

## 6. Log

One `maintain · Updated N notes` entry for the whole audit, not one per note; a report-only audit
is one `lint · Audited` entry with a count per defect class. Format in
[`wiki-audit-trail`](../../wiki-audit-trail/SKILL.md).

## 7. Verify

Re-run steps 1 and 3. Every defect you fixed is gone in the file itself, and the approved user tags
are intact.
