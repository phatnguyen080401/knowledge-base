---
name: wiki-query
description: Answer a question about the wiki's subject matter from the vault, citing pages and filing new synthesis back. Use when the user asks a subject question rather than for an edit, "what does the vault say about X", or "compare X and Y".
argument-hint: "<question>"
---

# Wiki Query

Answering is not read-only: per `AGENTS.md` §1.12, an answer that produced something worth keeping
is filed back.

## Steps

1. **Route.** Grep `wiki/hot.md` for two to four distinctive terms of the question
   (`grep -niE '<term>|<acronym>|<synonym>' wiki/hot.md`); never read it whole. An entry whose gist
   matches the question is **fresh** when no cited note's `updated` (`grep -m1 '^updated:' <note>`)
   is later than the entry's timestamp. Fresh → read only its cited sections and skip the index.
   No match, stale, or not enough → read `wiki/INDEX.md` and shortlist candidate pages from the
   summaries before opening any file.
2. **Read what answers the question.** A note under ~15 KB (`wc -c`) is read in full. For a larger
   one, read its frontmatter and definition (the first ~15 lines) and its heading list
   (`grep -n '^#' <note>`), then only the relevant sections (Read with offset and limit); read it
   whole when the question is about its topic as a whole. Follow `## Related Concepts` one hop out
   when the question spans concepts.
3. **Answer with citations.** Every substantive claim carries the piped wikilink of the page it came
   from, so the user can tell vault knowledge from your own.
4. **Declare the gaps; never fill them silently.** If the wiki does not cover part of the question,
   say so and label anything from general knowledge as *outside the wiki*. Answering from your own
   weights while implying the vault said it is the worst failure of this workflow (`AGENTS.md`
   §1.9).
5. **File the answer back.** Decide which of these applies (more than one may):

   | The answer… | File |
   | --- | --- |
   | Merely restates what a page already says | Nothing |
   | Synthesized two or more pages into something neither has | A new page per `AGENTS.md` §3, or a new section on the better-fitting page |
   | Exposed a missing concept | A `stub`, linked both ways |
   | Exposed a conflict or an unverified claim | An entry under `## Open Questions & Disagreements`, tagged `needs-review` |
   | Corrected a page | Fix the page in the same action and bump `updated` |

   When it is a judgement call, propose the page and ask before writing. Any write follows the
   usual rules: tags via [`tag-taxonomy`](../tag-taxonomy/SKILL.md), body per
   [obsidian-syntax.md](../wiki-lint/references/obsidian-syntax.md), links both ways, `INDEX.md`
   updated.
6. **Remember the route.** If the vault answered the question, add or refresh its `wiki/hot.md`
   entry (below). Skip it when the vault did not cover the question.
7. **Log it.** One `query` entry naming the pages read and what was filed, including
   `Filed: nothing`; the hot.md update is folded in. Format in
   [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md).

## `wiki/hot.md`

A router, never a source: each entry points to the sections that answered a past question, so a
repeat skips the index and the unread parts of long notes. Answers still read and cite those
sections.

```markdown
- **<question gist>** → [[concepts/<folder>/<note>#<Heading>|<Note> › <Heading>]], … — <gist of the answer, ≤25 words>. · YYYY-MM-DD HH:mm:ss
```

- One line per entry, newest first, directly under the purpose line; no blank lines between
  entries. Insert like a log entry: read only the first 5 lines, then edit.
- Cite the sections that carried the answer; a whole note only when no heading fits. The timestamp
  is the request's clock reading.
- Refreshing an entry deletes the old line (find it with `grep -n`) and inserts the new one at the
  top. At most 40 entries: past that, delete the last line.
- It is not listed in `INDEX.md`, and its links do not count toward reachability.

## Definition of Done

- [ ] `wiki/hot.md` was grepped first; without a fresh route, `INDEX.md` was read before any page.
- [ ] Every substantive claim cites its page; anything else is labelled *outside the wiki*.
- [ ] New synthesis, missing concepts, conflicts, and corrections were filed, or proposed and asked about; hot.md holds the route.
- [ ] `wiki/log.md` has one `query · Answered` entry, including when nothing was filed.
