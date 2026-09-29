---
name: tag-taxonomy
description: Enforce consistent tagging across the Obsidian wiki using a controlled vocabulary. Use this skill when the user says "fix my tags", "normalize tags", "clean up tags", "tag audit", "what tags should I use", "tag taxonomy", or whenever you're creating or updating wiki pages and need to choose the right tags. Also trigger when the user asks about tag conventions, wants to add a new tag to the taxonomy, or says "my tags are a mess". Always consult this skill's taxonomy file before assigning tags to any wiki page.
---

# Tag Taxonomy

Every note carries a **mandatory tag set drawn from a controlled vocabulary** — a `domain` tag plus
at least one `topic` tag — and may carry **optional extra tags supplied by the user**. The approved
vocabulary lives in [taxonomy.md](references/taxonomy.md). Read that file before you assign, change,
or audit a single tag.

This skill operates under `AGENTS.md`, which always wins on conflict. In particular: tags are
lowercase `kebab-case`, every frontmatter change bumps `updated`, and every write under `wiki/`
needs a `wiki/log.md` entry. The `AGENTS.md` §3 requirement of at least one topical tag is tightened
here to a mandatory set of a `domain` tag plus at least one `topic` tag; optional user tags sit on
top of it and are only ever added at the user's explicit request. A note carries **at most 10 tags
in total**, mandatory and optional combined.

## Core Rules

1. **Mandatory tags are a closed vocabulary.** Every tag *you* assign must be listed in
   [taxonomy.md](references/taxonomy.md). If nothing fits, follow "Adding a New Tag" below — do not
   invent one inline.
2. **Facets.** The mandatory set is exactly one `domain` tag, at least one `topic` tag, and zero or
   one `lifecycle` tag — always present on every note. A note never exceeds 10 tags in total.
3. **Optional user tags.** The user may add tags of their own beyond the mandatory set. Honour them:
   they are not vocabulary errors and you never strip them during an audit. They still must be
   lowercase `kebab-case`, must not be a banned tag, must not duplicate or contradict a mandatory
   tag, and they do count toward the 10-tag ceiling. Add one yourself only when the user asks for it
   by name.
4. **Never use a general, useless, arbitrary, ambiguous, or uninformative tag.** A tag must tell a
   reader something the note's location, title, and other tags do not already say. If it would apply
   to almost every note, or you cannot state in one sentence what it excludes, leave it off.
   `concept`, `data`, `general`, `misc`, `important`, `todo` and their kin are banned — see the
   Banned Tags table in [taxonomy.md](references/taxonomy.md). This binds mandatory and user tags
   alike; if the user requests such a tag, say so and propose a specific alternative before writing.
5. **Tag the subject, not the title.** A tag describes the field a note belongs to. A note does not
   need a tag that merely repeats its own filename.
6. **Singular, kebab-case, no `#`.** `data-quality`, not `Data Quality`, `dataQuality`, `data_quality`,
   `#data-quality`, or `data-qualities`.
7. **`stub` is temporary.** Add it when the note is a placeholder; remove it the moment the note
   becomes substantive. A `stub` tag on a full page is a defect.
8. **Never leave `tags:` empty.** A note without its mandatory set is a lint failure, not a valid
   state. Optional user tags alone do not satisfy the requirement.

## Choosing Tags for a Page

Run this in order, every time you create or update a note:

1. Read [taxonomy.md](references/taxonomy.md).
2. Pick the single `domain` tag that best describes the field the note belongs to. If two domains
   seem equally right, the note probably covers two concepts — see `AGENTS.md` §4.3 about splitting.
3. Add at least one `topic` tag — this is required, not optional. Add further topic tags only while
   each one carries information none of the others already imply; stop as soon as a tag would be
   redundant. If no approved topic fits, the vocabulary has a gap: follow "Adding a New Tag" instead
   of leaving the note topicless.
4. Add `stub` if the note is a placeholder, or `needs-review` if its content is unverified or
   conflicts with another page. That completes the mandatory set.
5. Carry over any optional user tags the note already has, and add new ones only if the user asked
   for them in this request.
6. Order tags `domain`, then `topic`(s), then `lifecycle`, then optional user tags last. Consistent
   order makes diffs readable and keeps the mandatory set visible at a glance.
7. Verify each mandatory tag appears verbatim in [taxonomy.md](references/taxonomy.md), and that the
   note carries no more than 10 tags.

## Workflow: Tag Audit / Normalization

Triggered by "fix my tags", "normalize tags", "clean up tags", "tag audit", "my tags are a mess".

1. **Collect.** Search every file in `wiki/concepts/` for its `tags:` line and build the current
   tag inventory with a count per tag.
2. **Classify** each distinct tag found:
   - **Approved** — listed in [taxonomy.md](references/taxonomy.md). Leave alone.
   - **Known alias** — listed in the Alias Map in [taxonomy.md](references/taxonomy.md). Rewrite to its canonical tag.
   - **Banned** — general, useless, arbitrary, ambiguous, or uninformative. Remove it, then make
     sure the note still has a complete mandatory set.
   - **Unknown** — not in the taxonomy at all. It is either a typo, a candidate for the vocabulary,
     or a deliberate user tag. Propose a mapping and ask; do not guess, and never delete it unilaterally.
3. **Fill gaps.** Any note that is missing a `domain` tag, lacks a `topic` tag, or exceeds 10 tags
   gets a corrected mandatory set proposed for it.
4. **Report before writing.** Show the user a table of `file → current tags → proposed tags` plus a
   list of unknown tags and what you propose to do with each, flagging which ones you believe are
   intentional user tags to keep. Get approval. This is mandatory when the change touches more than
   ~10 notes (`AGENTS.md` prohibited actions).
5. **Apply.** For each approved change, rewrite the `tags` line and set `updated` to the real
   current time from `date +"%Y-%m-%d %H:%M:%S"`. Touch nothing else in the note.
6. **Log.** Append one `wiki/log.md` entry per logical action, newest first:
   `- **YYYY-MM-DD**: Updated \`[[concepts/note_name]]\` — normalized tags to controlled vocabulary.`
   A vault-wide sweep may be logged as a single entry that names the affected notes.
7. **Verify.** Re-run step 1 and confirm every note has exactly one `domain` tag, at least one
   `topic` tag, no more than 10 tags in total, every mandatory tag in the taxonomy, approved user
   tags intact, and no `stub` on a substantive page.

`wiki/INDEX.md` is grouped by topic, not by tag, so a tag-only change usually leaves it untouched.
Check it anyway — if a retag reveals a note is filed under the wrong `##` group, fix the grouping
and say so in your report.

## Adding a New Tag

A new tag is a change to the vocabulary and needs explicit user approval. Propose one only when:

- it applies to **three or more** existing or imminent notes (a one-off tag is noise), **and**
- no approved tag or combination already covers it, **and**
- it fits cleanly into exactly one facet.

Then: state the proposed tag, its facet, its one-line definition, and the notes it would apply to.
On approval, add it to the correct facet table in [taxonomy.md](references/taxonomy.md) in alphabetical order,
apply it, and log the vocabulary change in `wiki/log.md`.

Retiring a tag is the same process in reverse: add the old tag to the Alias Map pointing at its
replacement (or mark it removed), retag every affected note, and log it.

## Definition of Done

- [ ] Every touched note's mandatory tags appear verbatim in [taxonomy.md](references/taxonomy.md).
- [ ] Every touched note has exactly one `domain` tag, at least one `topic` tag, and no more than 10 tags in total, in facet order.
- [ ] Optional user tags were preserved, follow `kebab-case`, and are listed after the mandatory set.
- [ ] No general, useless, arbitrary, ambiguous, or uninformative tag remains anywhere in
      `wiki/concepts/`, and every unknown tag was resolved with the user.
- [ ] `stub` appears only on genuine placeholders.
- [ ] `updated` was bumped from the system clock on every note whose frontmatter changed.
- [ ] `wiki/log.md` records the change; `wiki/INDEX.md` still matches `wiki/concepts/`.
- [ ] Any new tag was approved by the user and written into [taxonomy.md](references/taxonomy.md).
