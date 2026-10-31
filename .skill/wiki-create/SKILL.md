---
name: wiki-create
description: Create, expand, or stub a concept note in `wiki/concepts/` on a direct request with no source file or URL. Use when the user says "create a note on X", "new page for X", "add a note about X", "write up X", "expand the note on X", or "stub out X". For files in `raw/` or a URL to ingest, use wiki-ingest.
argument-hint: "<topic>"
---

# Wiki Create

The direct-request path of `AGENTS.md` §4, as ordered steps.

## 1. Clock

Read it once (`AGENTS.md`) and reuse it for every timestamp and the log entry.

## 2. Search

1. Search `wiki/concepts/` by filename and by content: the name, its acronym, plurals, and synonyms.

   ```bash
   find wiki/concepts -iname '*<term>*'
   grep -rli '<term>\|<acronym>\|<synonym>' wiki/concepts
   ```

2. Unless a page clearly covers the concept, read `wiki/INDEX.md` in full and shortlist pages whose
   summaries touch it before deciding to create.

| Result | Action |
| --- | --- |
| A page covers the concept | **Expand** it (step 4) |
| No page covers it | **Create** (step 4) |
| Partial or ambiguous overlap, or unclear scope | Stop and ask the user which page, or whether to split |
| The covering page is **ingested** | **Create** a note on the narrower concept that links to it; ask if that would duplicate it |

A request covering several concepts becomes several notes, or one note plus stubs.

**Ingested notes are read-only here.** A note whose `sources` lists a `raw/processed/` file belongs
to [`wiki-ingest`](../wiki-ingest/SKILL.md): this skill never expands it, adds links to it, or bumps
its `updated`, unless the user names that note in the request. Linking *to* it is fine.

## 3. Tags and Folder

Choose them with [`tag-taxonomy`](../tag-taxonomy/SKILL.md), reading it and its
`references/taxonomy.md` first. Add `stub` when the note will be a placeholder.

## 4. Write

**Create:** a new `snake_case.md` in the domain folder, in the `AGENTS.md` §3 shape, with `created`
and `updated` both set to the clock reading and `sources` only if a URL or file contributed. Write
the body per [obsidian-syntax.md](../wiki-lint/references/obsidian-syntax.md).

**Expand:** merge into the right existing sections, rewriting sentences to integrate the new facts;
never bolt on an "Update" section or replace content wholesale without approval. Re-check the tags,
append any new `sources`, and set `updated`; never change `created`.

## 5. Link Both Ways

- Outbound: links per `AGENTS.md` §3; every target exists.
- Inbound: add a link back from at least one related existing, non-ingested note, under its
  `## Related Concepts` or at a natural mention, and bump that note's `updated`.
- Ask before stubbing a related concept the user did not request; otherwise leave it unlinked.

## 6. Index and Log

Add or rewrite the `wiki/INDEX.md` entry and write one `maintain` log entry (`Created` or
`Expanded`), both per [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md).

## 7. Verify and Report

Run `AGENTS.md` §9 on every touched note (report semantic findings; don't fix them), the
obsidian-syntax.md Checks on the body, and the INDEX diff from wiki-audit-trail. Report the note
created or expanded, its tags and folder, links added each way, and any open questions.

## Definition of Done

Every step above is complete and `AGENTS.md` §9 passes on every touched note, plus:

- [ ] The vault was searched by name, acronym, and synonym before writing; no near-duplicate exists.
- [ ] The body passes the obsidian-syntax.md Checks.
- [ ] No ingested note was modified, unless the user named it.
