---
name: wiki-resolve
description: Resolve a note's open questions, fact-check stale or unsourced claims, or expand stubs, from cited sources. Use when the user says "resolve the open questions on X", "review the needs-review notes", "fact-check X", "is X still current", "expand the stubs", "research the next questions", or "follow up on the lint report".
argument-hint: "[note | needs-review | stubs]"
---

# Wiki Resolve

Closes the gaps the vault already records: `## Open Questions & Disagreements` entries, `stub`
notes, and the stale, unsourced, and next-question findings of a lint pass. Every answer comes from
a cited source or the user, never from model memory alone (`AGENTS.md` §1.9).

## 1. Targets

- the note the user named; or
- `needs-review`: notes tagged `needs-review` or with a non-empty Open Questions section
  (`grep -rl '^## Open Questions' wiki/concepts`); or
- `stubs`: notes tagged `stub`, most-linked first; or
- the stale, unsourced, and next-question items of the latest lint report in this conversation.

Read each target note in full.

## 2. Triage

Sort every item and show the user the triage before researching:

| Class | Example | Path |
| --- | --- | --- |
| **Resolvable** | A claim a specification, official doc, or paper can settle | Research (step 3) |
| **User decision** | A naming or scope choice only the user can make | Ask |
| **Standing disagreement** | Sources that genuinely and lastingly disagree | Leave it recorded; ask whether the note keeps `needs-review` (a tag the user removed by hand is reported, not restored) |

## 3. Research

Primary sources first (specification, official documentation, paper), read in full, through your
web tools or material the user supplies. Record the version or date of any time-sensitive fact. A
vendor's documentation is the vendor's claim; say so where it matters. An item nothing settles
stays open.

## 4. Propose, Then Apply

Report each item as *finding → citation → proposed edit*, and wait for approval. Then, from one
clock reading:

- **Resolved:** merge the answer into the right section, rewriting sentences rather than appending
  an "Update"; add the quoted URL (or `raw/processed/` file) to `sources`; delete the bullet.
- **Still open:** keep the bullet and add, in one clause, what was checked and when.
- **Section now empty:** delete it and remove `needs-review` (`AGENTS.md` §3).
- **Stub expanded:** write real sections per `AGENTS.md` §3 and
  [obsidian-syntax.md](../wiki-lint/references/obsidian-syntax.md), and remove `stub` and the
  INDEX `**Stub.**` marker.
- Re-check tags with [`tag-taxonomy`](../tag-taxonomy/SKILL.md), rewrite the INDEX summary only if
  the note's scope changed, and bump `updated`.

## 5. Log and Verify

One `maintain · Updated` entry per [`wiki-audit-trail`](../wiki-audit-trail/SKILL.md), e.g.
"resolved 2 of 3 open questions", with a `Source:` clause naming the main source. Then run
`AGENTS.md` §9 and the obsidian-syntax.md Checks on every touched note.

## Definition of Done

Every step above is complete and `AGENTS.md` §9 passes on every touched note, plus:

- [ ] Every resolution cites a source in `sources` or records the user's decision.
- [ ] Unsettled items are still listed, and `needs-review` matches the section or the mismatch was reported as a hand edit.
