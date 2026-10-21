---
name: tag-taxonomy
description: Tag every wiki note across six facets — `domain` (the field), `topic` (the sub-area), `concept` (the mechanisms it explains), `tech` (the named products and standards it covers), `type` (overview, comparison, how-to), and `lifecycle` (stub, needs-review) — using the controlled vocabulary in references/taxonomy.md. Use this skill whenever you create or update a note and must choose its tags, and when the user says "fix my tags", "normalize tags", "clean up tags", "tag audit", "retag", "what tags should I use", "tag taxonomy", "my tags are a mess", asks how notes are classified by domain or technology, or wants to add a tag to the vocabulary. Always read the taxonomy file before assigning a single tag.
---

# Tag Taxonomy

A note's tag line answers six questions in a fixed order: **what field** it belongs to, **what
sub-area** within that field, **which mechanisms** it explains, **which named technologies** it
covers, **what shape** of note it is, and **what state** it is in. Each question is one facet. The
approved vocabulary lives in [taxonomy.md](references/taxonomy.md) — read that file before you
assign, change, or audit a single tag.

```yaml
tags: [<domain>, <topic…>, <concept…>, <tech…>, <type>, <lifecycle>, <user…>]
```

| Facet       | Count per note | Answers                                        | Vocabulary |
| ----------- | -------------- | ---------------------------------------------- | ---------- |
| `domain`    | exactly 1      | Which field is this?                           | Closed     |
| `topic`     | 1–3            | Which sub-area of that field?                  | Closed     |
| `concept`   | 0–4            | Which mechanisms or ideas does it explain?     | Closed     |
| `tech`      | 0–4            | Which named products, platforms, or standards? | **Open**   |
| `type`      | 0–1            | Is it an overview, a comparison, or a how-to?  | Closed     |
| `lifecycle` | 0–1            | Is it a stub, or does it need review?          | Closed     |

Facets 1–2 are the **mandatory set**: no note is validly tagged without them. A **substantive**
(non-`stub`) note additionally needs at least one `concept` **or** one `tech` tag, so the tag line
says what the note is actually about and not just where it is filed; `overview` hub notes are
exempt, since their substance is the links they carry. The user may add **optional tags** of their
own on top; those are honoured, never invented, and never stripped. A note carries **at most 10
tags in total**.

This skill operates under `AGENTS.md`, which always wins on conflict: tags are lowercase
`kebab-case`, every frontmatter change bumps `updated` from the real clock, and every write under
`wiki/` needs a `wiki/log.md` entry.

## Core Rules

1. **Closed facets are a closed vocabulary.** Every `domain`, `topic`, `concept`, `type`, and
   `lifecycle` tag you assign must appear verbatim in [taxonomy.md](references/taxonomy.md). If
   nothing fits, follow "Adding a New Tag" below — do not invent one inline.
2. **`tech` is the one open facet.** Product, platform, and standard names are unambiguous and
   self-documenting, so you may add a new one on first use without approval. Use the canonical
   lowercase name (`bigquery`, not `google-bigquery` or `BigQuery`), never a version number
   (`dbt`, not `dbt-1-8`), and never a category dressed up as a product (`warehouse` is a topic,
   not a tech). Record it in the seed table once a second note uses it.
3. **One domain, always.** If two domains seem equally right, the note probably covers two concepts
   — see `AGENTS.md` §4.3 about splitting it.
4. **Earn every extra tag.** Add a tag only while it carries information none of the others already
   imply. A `concept` tag must be shared by at least two notes; a concept that lives on exactly one
   page is that page's title, not a classification.
5. **Never use a general, useless, arbitrary, ambiguous, or uninformative tag.** A tag must tell a
   reader something the note's location, title, and other tags do not already say. If it would apply
   to almost every note, or you cannot state in one sentence what it excludes, leave it off.
   `concept`, `data`, `general`, `misc`, `important`, `todo` and their kin are banned — see the
   Banned Tags table in [taxonomy.md](references/taxonomy.md). This binds user tags too; if the user
   requests such a tag, say so and propose a specific alternative before writing.
6. **Tag the subject, not the title** — except for `tech`. A `domain`, `topic`, or `concept` tag
   that merely restates the filename adds nothing. A `tech` tag on its own namesake note is
   *correct*, because its job is to cluster the whole product family: `dbt.md`, its adapters, and
   its deployment note all carry `dbt`.
7. **The table is the spelling.** Lowercase `kebab-case`, no `#`, and copy the tag exactly as its
   facet table writes it — `data-quality`, not `Data Quality`, `dataQuality`, `data_quality`, or
   `data-qualities`. Number is not a style choice: the vocabulary holds both `data-quality` and
   `databases`, so never "correct" a tag's plural to match a rule of thumb.
8. **`stub` and `needs-review` are temporary.** Remove `stub` the moment the note becomes
   substantive; a `stub` tag on a full page is a defect. `needs-review` stays only while the note
   has a non-empty `## Open Questions & Disagreements` section.
9. **Optional user tags are preserved.** They are not vocabulary errors and you never strip them in
   an audit. They must still be lowercase `kebab-case`, must not be banned, must not duplicate a
   facet tag, and they count toward the 10-tag ceiling. Add one yourself only when the user asks for
   it by name.
10. **Never leave `tags:` empty.** A note without its mandatory set is a lint failure, not a valid
    state. Optional user tags alone do not satisfy the requirement.

## Choosing Tags for a Page

Run one pass per facet, in order, every time you create or update a note. Read the note's body
first — tag what it actually explains, not what its filename suggests.

1. **Read** [taxonomy.md](references/taxonomy.md).
2. **Domain** — pick the single field the note belongs to. Use the *Excludes* column to break ties;
   if it still splits two ways, the note covers two concepts.
3. **Topic** — pick the most specific approved topic that honestly fits, then add a second or third
   only while each narrows the note further. If no topic fits, the vocabulary has a gap: follow
   "Adding a New Tag" rather than leaving the note topicless.
4. **Concept** — list the mechanisms or ideas the note *explains*, not the ones it merely mentions
   in passing. Keep those already in the taxonomy; for anything else, check whether a second note
   would use it before proposing it.
5. **Tech** — name every product, platform, or standard the note is substantively about, including
   the one in its own title. A product mentioned once as an example is not a `tech` tag.
6. **Type** — add `overview` for a hub note that mainly routes to others, `comparison` for a note
   whose subject is the difference between two things, `how-to` for a procedure. Ordinary
   explanatory notes take no type tag.
7. **Lifecycle** — add `stub` for a placeholder, `needs-review` when the content is unverified or
   conflicts with another page.
8. **Carry over** any optional user tags already on the note; add new ones only if the user asked
   for them in this request.
9. **Verify** — facet order, ≤10 tags, every closed-facet tag verbatim in the taxonomy, and the
   substantive-note rule (at least one `concept` or `tech`, unless the note is an `overview`).

### Worked examples

| Note                                  | Tags                                                                               | Why                                                                      |
| ------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `acid.md`                             | `[databases, transactions, concurrency-control, consistency-models]`               | Two mechanisms it genuinely explains; no product involved                |
| `cap_theorem.md`                      | `[databases, distributed-systems, consistency-models, replication, partitioning]`  | Multi-node topic; three distinct mechanisms                              |
| `bloom_filter.md`                     | `[data-structures, indexing, probabilistic-structures]`                            | Vendor-neutral structure theory, so no `tech`                            |
| `lsm_tree.md`                         | `[data-structures, indexing, write-optimization]`                                  | `write-optimization` is what distinguishes it from the B-tree notes      |
| `dbt_bigquery_adapter.md`             | `[data-engineering, elt, dbt, bigquery]`                                           | Substance is product behaviour, so `tech` carries it instead of `concept`|
| `deploy_dbt_cloud_run_github_actions.md` | `[data-engineering, deployment, ci-cd, dbt, cloud-run, github-actions, how-to]` | A procedure spanning three named technologies                            |
| `semantic_layer_vs_ontology_layer.md` | `[data-architecture, data-modeling, metric-definition, knowledge-graph, comparison]`| The subject *is* the contrast, so `comparison`                           |
| `data_structures_algorithms.md`       | `[data-structures, indexing, overview]`                                            | Hub note — exempt from the concept-or-tech rule                          |
| `fix_protocol.md`                     | `[software-architecture, api-protocols, compatibility-contracts, fix-protocol]`    | `tech` repeats the title on purpose, to cluster the protocol's notes     |

## Workflow: Tag Audit / Normalization

Triggered by "fix my tags", "normalize tags", "clean up tags", "tag audit", "my tags are a mess".

1. **Collect.** Search every file in `wiki/concepts/` for its `tags:` line and build the current
   tag inventory with a count per tag.
2. **Classify** each distinct tag found:
   - **Approved** — listed in a closed-facet table in [taxonomy.md](references/taxonomy.md), or a
     well-formed `tech` name. Leave alone.
   - **Retired** — listed in the Retired Tags table in [taxonomy.md](references/taxonomy.md).
     Rewrite to its replacement; the decision is already made, so do not re-open it.
   - **Banned** — general, useless, arbitrary, ambiguous, or uninformative. Remove it, then make
     sure the note still has a complete mandatory set.
   - **Unknown** — not in the taxonomy at all. It is either a typo, a malformed `tech` name, a
     candidate for a closed facet, or a deliberate user tag. Propose a mapping and ask; do not
     guess, and never delete it unilaterally.
3. **Fill gaps.** Propose a corrected tag set for any note that is missing a `domain` tag, lacks a
   `topic` tag, is substantive but carries neither a `concept` nor a `tech` tag, names a technology
   in its body that is absent from its tags, has its facets out of order, or exceeds 10 tags.
4. **Report before writing.** Show the user a table of `file → current tags → proposed tags` plus a
   list of unknown tags and what you propose to do with each, flagging which ones you believe are
   intentional user tags to keep. Get approval. This is mandatory when the change touches more than
   ~10 notes (`AGENTS.md` prohibited actions).
5. **Apply.** For each approved change, rewrite the `tags` line and set `updated` to the real
   current time from `date +"%Y-%m-%d %H:%M:%S"`. Touch nothing else in the note.
6. **Log.** Append one `wiki/log.md` entry per logical action, newest first:
   `- **YYYY-MM-DD HH:mm:ss** · maintain · Updated \`[[concepts/<folder>/note_name]]\` — retagged to the six-facet vocabulary.`
   A vault-wide sweep may be logged as a single entry that names the affected notes.
7. **Verify.** Re-run step 1 and confirm every note has exactly one `domain` tag, at least one
   `topic` tag, a `concept` or `tech` tag where the rule requires it, facets in order, no more than
   10 tags in total, every closed-facet tag in the taxonomy, approved user tags intact, and no
   `stub` on a substantive page.

`wiki/INDEX.md` is grouped by topic, not by tag, so a tag-only change usually leaves it untouched.
Check it anyway — if a retag reveals a note is filed under the wrong `##` group, fix the grouping
and say so in your report.

## Adding a New Tag

A `tech` tag needs no ceremony — Core Rule 2 — but every **closed-facet** tag is a change to the
vocabulary and needs explicit user approval. Propose one only when:

- it applies to **three or more** existing or imminent notes for a `domain`, `topic`, or `type`
  tag, or **two or more** for a `concept` tag (concepts are finer-grained, so they earn their place
  sooner), **and**
- no approved tag or combination already covers it, **and**
- it fits cleanly into exactly one facet.

Then: state the proposed tag, its facet, its one-line **Covers** and **Excludes** definition, and
the notes it would apply to. On approval, add it to the correct facet table in
[taxonomy.md](references/taxonomy.md) in alphabetical order, apply it, and log the vocabulary change
in `wiki/log.md`.

Retiring a tag is the same process in reverse: retag every affected note, log it, and add a row to
the Retired Tags table in [taxonomy.md](references/taxonomy.md) naming the replacement and the
reason — that row is the only record of *why*, since the log entry will scroll out of easy reach.

## Definition of Done

- [ ] Every touched note's `domain`, `topic`, `concept`, `type`, and `lifecycle` tags appear verbatim in [taxonomy.md](references/taxonomy.md).
- [ ] Every touched note has exactly one `domain` tag, 1–3 `topic` tags, and no more than 10 tags in total, in facet order.
- [ ] Every substantive note carries at least one `concept` or `tech` tag; `overview` hubs are exempt.
- [ ] Every `tech` tag is a canonical, version-free product, platform, or standard name, and every technology the note is substantively about is tagged.
- [ ] Optional user tags were preserved, follow `kebab-case`, and are listed after the facet tags.
- [ ] No general, useless, arbitrary, ambiguous, or uninformative tag remains anywhere in
      `wiki/concepts/`, and every unknown tag was resolved with the user.
- [ ] `stub` appears only on genuine placeholders, and `needs-review` only where an `## Open Questions & Disagreements` section is non-empty.
- [ ] `updated` was bumped from the system clock on every note whose frontmatter changed.
- [ ] `wiki/log.md` records the change; `wiki/INDEX.md` still matches `wiki/concepts/`.
- [ ] Any new closed-facet tag was approved by the user and written into [taxonomy.md](references/taxonomy.md); any new `tech` tag used twice was added to its seed table.
