---
name: wiki-query
description: Answer a question from the vault — read INDEX.md first, read the shortlisted pages in full, answer with a piped-wikilink citation for every claim, label anything outside the wiki, then file new synthesis, stubs, conflicts, or corrections back into the vault and log one `query` entry. Use this skill whenever the user asks a question about the wiki's subject matter (rather than asking for an edit), asks "what does the vault say about X", "compare X and Y", or runs `/wiki-query`.
argument-hint: "<question>"
---

# Wiki Query

**As a command:** when the user runs `/wiki-query <question>`, the question is `$ARGUMENTS`. Read `AGENTS.md` first if it is not already in context. If no question was given, ask for one instead of guessing.

The procedure for answering a question about the wiki's subject matter. The wiki is the answer
source, and answering is not a read-only act: per `AGENTS.md` §1.12, an answer that produced
something worth keeping is filed back.

This skill operates under `AGENTS.md`, which wins on conflict.

## Steps

1. **Index first.** Read `wiki/INDEX.md` and shortlist candidate pages from the summaries. Only
   then open files. Do not search the whole vault before consulting the index.
2. **Read the shortlist in full.** Read the pages, not fragments of them. Follow
   `## Related Concepts` links one hop out when the question spans concepts.
3. **Answer with citations.** Every substantive claim carries the piped wikilink of the page it
   came from, so the user can tell vault knowledge from your own.
4. **Declare the gaps; never fill them silently.** If the wiki does not cover part of the
   question, say so explicitly and label anything you add from general knowledge as *outside the
   wiki*. Answering from your own weights while implying the vault said it is the worst failure of
   this workflow, and an `AGENTS.md` §1.9 violation.
5. **File the answer back.** Decide which of these applies (more than one may):

   | The answer…                                              | File                                                                      |
   | -------------------------------------------------------- | ------------------------------------------------------------------------- |
   | Merely restates what a page already says                 | Nothing                                                                   |
   | Synthesized two or more pages into something neither has | A new page per `AGENTS.md` §3, or a new section on the better-fitting page |
   | Exposed a missing concept                                | A `stub`, linked both ways                                                |
   | Exposed a conflict or an unverified claim                | An entry under `## Open Questions & Disagreements`, tagged `needs-review` |
   | Corrected a page                                         | Fix the page in the same action and bump `updated`                        |

   When it is a judgement call, propose the page and ask before writing. Any write follows the
   usual rules: tags via [`tag-taxonomy`](../tag-taxonomy/SKILL.md), links both ways, `INDEX.md`
   updated.
6. **Log it.** One `query` entry per question naming the pages read and what was filed, including
   `Filed: nothing` when that was the right call. Do not restate the answer in the log. Format in
   [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md).

**Never** answer a vault question purely from memory without reading the pages, and never let a
question that produced something worth keeping leave the vault unchanged.

## Definition of Done

- [ ] `INDEX.md` was read before any page; shortlisted pages were read in full.
- [ ] Every substantive claim cites its page; anything else is labelled *outside the wiki*.
- [ ] New synthesis, missing concepts, conflicts, and corrections were filed, or proposed and asked about.
- [ ] `wiki/log.md` has one `query · Answered` entry, including when nothing was filed.
