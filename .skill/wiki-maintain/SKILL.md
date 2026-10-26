---
name: wiki-maintain
description: Rename, move, merge, split, or delete wiki notes and repoint every inbound link. Use when the user says "rename X to Y", "move X to <folder>", "change the domain of X", "merge X and Y", "these are duplicates", "split X", "this note covers two concepts", or "delete X", or when an approved lint or tag-audit fix moves or merges notes.
argument-hint: "<rename|move|merge|split|delete> <note> [target]"
---

# Wiki Maintain

The procedures behind `AGENTS.md` §7. Notes move, merge, or split here; what they say does not
change meaning.

## 1. Prepare

1. Read the clock once (`AGENTS.md`) and reuse it.
2. **Ask first** for a delete, the deletion step of a merge, a new domain or tech subfolder, or any
   change that touches more than ~10 notes (`AGENTS.md` §1, Prohibited).
3. **Find every inbound link** to each note you will move, merge, split, or delete (the bracket
   also catches `#Heading` anchors and table-escaped `\|` pipes):

   ```bash
   grep -rn '\[\[concepts/<folder>/<note>[]|#\\]' wiki/ --include='*.md' --exclude=log.md
   ```

   `wiki/log.md` keeps old paths forever, and `[[ … ]]` inside code is not a link. When a heading
   changes, also grep `#<old heading>`.

## 2. Operate

- **Rename or move.** `git mv` the file to its new path (`AGENTS.md` §2 naming). If the title
  changes, update `title`, the H1, and the definition sentence. A domain change retags with
  [`tag-taxonomy`](../tag-taxonomy/SKILL.md), whose domain table gives the folder; a new tech
  subfolder needs the product's `tech` tag on every note and a namesake hub note.
- **Merge.** Keep the richer page and integrate the other per `AGENTS.md` §1.3, with no appended
  section. Union both `sources` lists and both Open Questions sections, re-check the tags, then
  delete the merged-away file once approved.
- **Split.** Write the carved-out concept as a new note in the `AGENTS.md` §3 shape; the original
  keeps a one- or two-sentence summary that links to it. Copy the `sources` that support the moved
  content (never remove one from the original), move the matching Open Questions bullets, and
  recompute `needs-review` on both notes.
- **Delete.** With approval, repoint or unlink every inbound link, check that no note is left
  without an inbound link, then delete the file.

## 3. Repoint

Rewrite every hit from step 1, including links inside the moved notes and in `wiki/hot.md`, to the
new path. Keep the display text, any `#Heading` anchor, and the `\|` escape inside tables. Drop a
`hot.md` entry whose only note was deleted. Bump `updated` on every note whose content changed.

## 4. Index, Log, Verify

1. `wiki/INDEX.md`: move, add, or drop the entries, re-sort under the new title, and add or drop a
   `###` group and its `Folder:` line, per [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md).
2. One `maintain` log entry: `Renamed`, `Merged`, `Deleted`, or for a split `Created … split out
   of …`, with the number of links repointed in one clause.
3. Re-run the step 1 grep for every old path: it finds nothing. Run the INDEX diff and `AGENTS.md`
   §9 on every touched note.

## Definition of Done

Every step above is complete and `AGENTS.md` §9 passes on every touched note, plus:

- [ ] No link to an old path remains in a note, `INDEX.md`, or `hot.md`.
- [ ] Every deletion was approved, and no `sources` entry was lost.
