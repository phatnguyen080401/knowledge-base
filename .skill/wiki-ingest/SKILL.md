---
name: wiki-ingest
description: Compile source files from `raw/`, or a web page by URL, into wiki notes and archive them to `raw/processed/`. Use when the user says "ingest", "process raw/", "compile my notes", "import this file", "ingest this URL", or "clip this article", or drops a file into `raw/`. For a direct request with no file or URL, use wiki-create.
argument-hint: "[file|url]"
---

# Wiki Ingest

Compiles files in `raw/` into `wiki/concepts/`, as ordered steps under `AGENTS.md` §4.

## Steps

1. **Clock.** Read it once (`AGENTS.md`) and reuse it for every timestamp and the log entry.
2. **Scan.** Given a URL, clip it into `raw/` first ([below](#ingesting-a-url)). Otherwise list
   `raw/`, excluding `raw/processed/` and `raw/assets/`; if it is empty, report that and stop.
3. **Read the source** in full before deciding anything (a long PDF in page ranges). A binary the
   notes will embed goes to `raw/assets/`; a binary that is itself the source is archived to
   `raw/processed/` like any other.
4. **Identify concepts.** One raw file may hold several; split it, one concept per note. Never create
   a note that merely mirrors the source document's shape.
5. **Search before writing.** Search `wiki/concepts/` by filename *and* by content (name, acronym,
   plurals, synonyms). Unless a page clearly covers the concept, also read `wiki/INDEX.md` in full
   and shortlist from its summaries.

   | Result | Action |
   | --- | --- |
   | A page covers the concept | **Update** |
   | No page covers it | **Create** |
   | Ambiguous or partially overlapping | Ask the user; never create a near-duplicate |

6. **Write.**
   - **Create:** a new file in the `AGENTS.md` §3 shape, filled in as far as the source supports.
   - **Update:** merge into the correct existing section, rewriting sentences to integrate the new
     facts; no "Update" or "Additional Notes" section. Bump `updated`.
   - **Conflict:** never silently overwrite. Keep the better-sourced claim in the body **and**
     record both positions with their sources under `## Open Questions & Disagreements`, then tag
     `needs-review`. A conflict raised only in your chat summary will be forgotten.
   - Tags and folder with [`tag-taxonomy`](../tag-taxonomy/SKILL.md) on every create or update;
     body per [obsidian-syntax.md](../wiki-lint/references/obsidian-syntax.md).
7. **Link both ways.** Outbound links from every new or changed note, and a link back from at least
   one related existing note to each new one.
8. **Archive the source** to `raw/processed/` **only after** steps 6–7 succeed. If ingestion fails
   or is aborted, leave it in `raw/` so it is retried.
9. **Audit trail, last.** Append the archived path to each touched note's `sources`, update
   `wiki/INDEX.md`, and write **one** `ingest` log entry with a `Source:` clause, per
   [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md).
10. **Verify and report.** Run `AGENTS.md` §9 on every touched note (report semantic findings; don't
    fix them) and the obsidian-syntax.md Checks on every touched body. Summarize files ingested,
    notes created or updated, links added, and any conflicts or open questions.

## Ingesting a URL

1. **Already ingested?** `grep -rlF '<url>' raw/`. If a file holds the URL, report it and stop,
   unless the user asks for a refresh.
2. **Fetch** the page with your web tool, or ask the user to paste its text if you have none.
3. **Clip** its readable text (headings, body, tables, code; no navigation, ads, or comments) to
   `raw/<snake_case_title>.md`, whose first line is `Source: <url> (fetched <clock reading>)`.
   Images are saved to `raw/assets/` only if the user asks.
4. Continue at step 3 with that file. In step 9, `sources` gets both the archived path and the
   quoted URL.

## Definition of Done

Every step above is complete and `AGENTS.md` §9 passes on every touched note, plus:

- [ ] Every source was read in full and split one note per concept.
- [ ] Conflicts are recorded under `## Open Questions & Disagreements`, not only in chat.
- [ ] Every touched body passes the obsidian-syntax.md Checks.
