---
name: wiki-ingest
description: Ingest source files from `raw/` into the wiki — scan the intake queue, read each source in full, split it into concepts, search the vault before writing, create or merge notes (recording conflicts), tag and file them, link both ways, archive the source to `raw/processed/`, then update INDEX.md, the log, and `sources`. Use this skill whenever the user says "ingest", "process raw/", "compile my notes", "import this file", drops a file into `raw/`, or runs `/wiki-ingest`. For a direct request with no `raw/` file, use wiki-create instead.
argument-hint: "[file]"
---

# Wiki Ingest

The procedure for compiling files in `raw/` into `wiki/concepts/`. It applies the rules of
`AGENTS.md` §1 (rules), §3 (note format), and §6 (audit trail) as ordered steps.

This skill operates under `AGENTS.md`, which wins on conflict.

## Ground Rules

1. **Compile, don't retrieve.** Merge new facts into the existing page. Never paste raw source text
   verbatim or create a note that merely mirrors the source document's shape (`AGENTS.md` §1.3).
2. **Search before writing.** A near-duplicate page is the worst outcome (`AGENTS.md` §1.8).
3. **Idempotent.** Ingesting the same file twice must not change the vault the second time
   (`AGENTS.md` §1.10).
4. **Archive last.** A source moves to `raw/processed/` only after its notes are written and linked.

## Steps

1. **Clock.** Read it once and reuse the value for every `created`, `updated`, and the log entry.
2. **Scan.** List `raw/`, excluding `raw/processed/` and `raw/assets/`. If it is empty, report
   that and stop.
3. **Read the source.** Read the file in full before deciding anything. Move binaries to
   `raw/assets/` and describe what they depict.
4. **Identify concepts.** One raw file may contain several concepts. Split it, one concept per
   note.
5. **Search before writing.** Search `wiki/concepts/` by filename *and* by content (synonyms,
   acronyms, plurals), and check `wiki/INDEX.md`.

   | Result                               | Action                                              |
   | ------------------------------------ | --------------------------------------------------- |
   | A page covers the concept            | **Update**                                          |
   | No page covers it                    | **Create**                                          |
   | Ambiguous or partially overlapping   | Ask the user; never create a near-duplicate         |

6. **Write.**
   - **Create:** a new file in the `AGENTS.md` §3 shape, filled in as far as the source supports.
   - **Update:** merge into the correct existing section. Rewrite sentences to integrate the new
     facts; do not bolt on an "Update" or "Additional Notes" section. Bump `updated`.
   - **Conflict:** if new information contradicts the page, do not silently overwrite. Keep the
     better-sourced claim in the body, **and record both positions with their sources under
     `## Open Questions & Disagreements`**. A conflict raised only in your chat summary will be
     forgotten. Add `needs-review` to `tags`.
   - **Tag and file:** choose or re-check the tags with [`tag-taxonomy`](../tag-taxonomy/SKILL.md)
     on every create or update. The `domain` tag decides the folder; a note in a tech subfolder
     carries that product's `tech` tag.
   - **Syntax:** write the body with [obsidian-syntax.md](../wiki-lint/references/obsidian-syntax.md): piped
     full-path links, titled callouts, embeds only from `raw/assets/`, nothing from its banned list.
7. **Link both ways.** Add outbound wikilinks from the new or changed note, **and** add a link back
   from at least one related existing note so the page is reachable.
8. **Archive the source.** Move the raw file to `raw/processed/` **only after** steps 6–7 succeed.
   If ingestion fails or is aborted, leave it in `raw/` so it is retried.
9. **Audit trail.** Append each ingested source to the note's `sources` frontmatter, update
   `wiki/INDEX.md`, and append **one** `wiki/log.md` entry for the request with a
   `Source: raw/processed/<file>` clause (see [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md)).
   Mandatory, and always last.
10. **Report.** Summarize files ingested, notes created or updated, links added, and any conflicts
    or open questions.

## Definition of Done

- [ ] Every source was read in full and split into one note per concept.
- [ ] The vault was searched by name, acronym, and synonym before each write; no near-duplicate exists.
- [ ] Conflicts are recorded under `## Open Questions & Disagreements`, tagged `needs-review`.
- [ ] Every touched note links out, and at least one existing note links back to each new one.
- [ ] Each ingested source is in its notes' `sources` and now sits in `raw/processed/`; failed ones remain in `raw/`.
- [ ] `INDEX.md` matches the tree; `wiki/log.md` has one `ingest` entry from the same clock reading.
- [ ] The `AGENTS.md` §9 structural checks pass on every touched note.
- [ ] Every touched body passes the [obsidian-syntax.md](../wiki-lint/references/obsidian-syntax.md) Checks.
