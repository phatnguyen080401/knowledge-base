---
name: wiki-create
description: Create a new concept note in `wiki/concepts/`, or expand the existing one, on a direct request with no `raw/` file — search the vault first, pick tags and folder with tag-taxonomy, write the AGENTS.md §3 note shape, link both ways, update INDEX.md, log one entry, and verify. Use this skill whenever the user says "create a note on X", "new page for X", "add a note about X", "write up X", "expand the note on X", "stub out X", or runs `/wiki create`. For files waiting in `raw/`, follow AGENTS.md §4 ingestion instead.
---

# Wiki Create

The procedure for the **direct-request** path of `AGENTS.md` §4: the user names a concept and there
is no `raw/` file behind it. It strings together the rules of §3 (note format), §4 (search and
write), and §6 (audit trail) as ordered steps; it adds no rules of its own.

This skill operates under `AGENTS.md`, which wins on conflict.

## Ground Rules

1. **Search before writing.** A near-duplicate page is the worst outcome (`AGENTS.md` §1.8). An
   existing page on the concept is expanded, never shadowed by a new one.
2. **Never fabricate.** Write only what the user states or what is well-established general
   knowledge. Mark any inference explicitly. If the scope is unclear, ask (`AGENTS.md` §1.9).
3. **One concept per note.** A request covering several concepts becomes several notes, or one
   note plus stubs.
4. **Merge, don't overwrite.** Expanding a page rewrites sentences to integrate new facts. It never
   bolts on an "Update" section or replaces existing content wholesale without approval.

## 1. Clock

Read the clock once and reuse the value for `created`, `updated`, and the log entry.

```bash
date +"%Y-%m-%d %H:%M:%S"
```

## 2. Search

1. Read `wiki/INDEX.md` and shortlist pages whose summaries touch the concept.
2. Search `wiki/concepts/` by filename and by content: the name, its acronym, plurals, and
   synonyms.

```bash
find wiki/concepts -iname '*<term>*'
grep -rli '<term>\|<acronym>\|<synonym>' wiki/concepts
```

| Result                          | Action                                          |
| ------------------------------- | ----------------------------------------------- |
| A page covers the concept       | **Expand** it (step 4, expand path)             |
| No page covers it               | **Create** (step 4, create path)                |
| Partial or ambiguous overlap    | Stop and ask the user which page, or whether to split |

## 3. Tags and Folder

Read [`tag-taxonomy`](../tag-taxonomy/SKILL.md) and its `references/taxonomy.md` before choosing a
single tag. The `domain` tag fixes the folder; a note in a tech subfolder carries that product's
`tech` tag. Add `stub` when the note will be a placeholder. A new domain needs user approval.

## 4. Write

**Create path:** a new `snake_case.md` file in the domain folder, in the `AGENTS.md` §3 shape:

- Frontmatter: `title`, `tags` (inline list), `sources` only if a URL or file contributed,
  `created` and `updated` both set to the clock reading.
- `# <Title>` matching `title`, then a standalone definition paragraph linking the parent concept.
- `## Why It Matters` and topic-specific `##` sections, prose and bullets only.
- `## Open Questions & Disagreements` if anything is unverified or extrapolated; then tag
  `needs-review`.
- `## Related Concepts`, each link with a reason; `## References` last, if any.

**Expand path:** merge into the right existing sections, re-check the tags against the taxonomy,
append any new `sources`, and set `updated` to the clock reading. Never change `created`.

## 5. Link Both Ways

- Outbound: link the first meaningful mention of each related concept with
  `[[concepts/<folder>/file_name|Display Text]]`; every link resolves to an existing file.
- Inbound: add a link back from at least one related existing note, under its
  `## Related Concepts` or at a natural mention, and bump that note's `updated`.
- A related concept with no page gets a `stub` only if the user agrees, or it stays unlinked.

## 6. Index and Log

1. `wiki/INDEX.md`: add or rewrite the entry in its folder's group, alphabetized, with a one-line
   summary; append `**Stub.**` for a `stub` page. A new tech subfolder gets its own `###` group
   with a `Folder:` line.
2. `wiki/log.md`: one entry under `# Activity Log`, about 40 words, folding in the backlinks and
   index edit (`AGENTS.md` §6).

```markdown
- **YYYY-MM-DD HH:mm:ss** · maintain · Created `[[concepts/<folder>/note_name]]` — <what it covers and why>.
```

Use `Expanded` instead of `Created` for the expand path.

## 7. Verify and Report

Run the `AGENTS.md` §9 structural checks on every touched note, then confirm `INDEX.md` matches
the recursive listing of `wiki/concepts/`.

```bash
diff <(find wiki/concepts -name '*.md' | sed 's|^wiki/||; s|\.md$||' | sort) \
     <(grep -o '\[\[concepts/[^|]*' wiki/INDEX.md | sed 's|^\[\[||' | sort)
```

Report the note created or expanded, its tags and folder, links added each way, and any open
questions.

## Definition of Done

- [ ] The vault was searched by name, acronym, and synonym before writing; no near-duplicate exists.
- [ ] The note follows the `AGENTS.md` §3 shape, with tags from the taxonomy and a matching folder.
- [ ] The note links out, and at least one existing note links back to it.
- [ ] `INDEX.md` lists it in the right group with a current summary, and matches the tree.
- [ ] `wiki/log.md` has one entry for the request, timestamped from the same clock reading.
