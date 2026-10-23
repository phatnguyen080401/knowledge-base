# Tag Audit / Normalization

Read this when the user says "fix my tags", "normalize tags", "clean up tags", "tag audit",
"retag", or "my tags are a mess", or when an `AGENTS.md` §7 lint pass reaches tags. Read
[taxonomy.md](taxonomy.md) and the parent [SKILL.md](../SKILL.md) first. Their rules are the
standard this audit checks against.

**Report before writing.** An audit never edits a note until the user has seen the findings and
approved the changes. Approval is mandatory when the changes touch more than ~10 notes
(`AGENTS.md`, Prohibited actions).

## 1. Collect

Grep `^tags:` (with a few lines of context, to catch block lists) across `wiki/concepts/`. For each
note, record its path, folder, and tags. Build an inventory with a count per tag.

## 2. Classify every distinct tag

| Class       | Test                                                                         | Action                                                        |
| ----------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------- |
| **Approved** | In a closed-facet table, or a well-formed `tech` name                       | Leave it alone                                                |
| **Retired** | In the Retired Tags table                                                    | Rewrite it to its replacement; the decision is already made   |
| **Banned**  | In the Banned Tags table, or general enough to fit almost any note           | Remove it, then check the note still has its mandatory set    |
| **Typo**    | A case, plural, separator, acronym, or vendor-prefix variant of an approved tag | Rewrite it to the tag it obviously means                   |
| **Unknown** | None of the above                                                            | Propose a mapping and ask. It may be a deliberate user tag, a new `tech` name, or a vocabulary gap. Never delete it unilaterally |

## 3. Check every note

Each check below is a **defect**, which you propose to fix, or a **flag**, which you only report
for the user to judge.

| Check                                                                       | Kind   |
| --------------------------------------------------------------------------- | ------ |
| `tags` is a block list instead of an inline list                            | Defect |
| Missing a `domain` tag, missing a `topic`, or more than one `domain`        | Defect |
| Substantive note with neither a `concept` nor a `tech` tag (`overview` exempt) | Defect |
| A technology named substantively in the body is absent from `tech`          | Defect |
| Facets out of order, or more than 10 tags                                   | Defect |
| Folder does not match the `domain` tag                                      | Defect (the fix is a move, see §5) |
| A note in a tech subfolder lacks that subfolder's `tech` tag                | Defect |
| `stub` on a substantive page                                                | Defect |
| `needs-review` with no open questions, or open questions with no `needs-review` | Flag if the log shows a user hand edit; otherwise defect |
| A tag that restates the note's own title (not `tech`)                       | Flag   |
| `overview` on a note that does not route to child notes                     | Flag   |
| A topic borrowed from another domain to fill a gap                          | Flag (candidate for a new topic) |
| A concept tag used by fewer than two notes                                  | Flag (review only; never auto-remove) |
| A `tech` tag used by two or more notes with no seed-table row               | Defect (add the row) |

## 4. Report

Show the user:

- a table: `file → current tags → proposed tags`
- the list of unknown tags and what you propose for each, marking the ones you believe are
  intentional user tags to keep
- the flags, each with a one-line reason
- any candidate new closed-facet tags, with their Covers/Excludes and the notes they would apply to

Then wait for approval.

## 5. Apply

- **Tag-only change:** rewrite the `tags` line, keeping the inline form, and set `updated` from the
  real clock. Touch nothing else in the note. `wiki/INDEX.md` is unchanged, because it mirrors
  folders, not tags.
- **Domain change:** the file must move to the new domain's folder. That is a rename, so follow
  `AGENTS.md` §7: repoint every inbound wikilink and move the entry to its new `INDEX.md` group.
- **Vocabulary change** (approved new tag, seed row, retired row): edit [taxonomy.md](taxonomy.md).

## 6. Log

Write one `wiki/log.md` entry for the whole audit, not one per note, kept to a headline line
(`AGENTS.md` §6):

```markdown
- **YYYY-MM-DD HH:mm:ss** · maintain · Updated 14 notes — retagged to the six-facet vocabulary; 2 block lists inlined, `sanity-check` dropped. Taxonomy gained the `streaming` topic.
```

A report-only audit with no edits is a `lint` entry using the verb `Audited`, with one count per
defect class.

## 7. Verify

Re-run step 1 and step 3. Every defect you fixed is gone, the approved user tags are intact, and
`INDEX.md` still matches the recursive listing of `wiki/concepts/`.
