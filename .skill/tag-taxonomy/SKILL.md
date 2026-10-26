---
name: tag-taxonomy
description: Tag every wiki note across six facets — `domain` (the field, which also fixes the note's folder), `topic` (the sub-area), `concept` (the mechanisms it explains), `tech` (the named products and standards it covers), `type` (overview, comparison, how-to), and `lifecycle` (stub, needs-review) — using the controlled vocabulary in references/taxonomy.md. Use this skill whenever you create, update, move, or file a note and must choose its tags or its folder, and when the user says "fix my tags", "normalize tags", "clean up tags", "tag audit", "retag", "what tags should I use", "tag taxonomy", "my tags are a mess", asks how notes are classified by domain or technology, or wants to add or retire a tag. Always read the taxonomy file before assigning a single tag; read references/audit.md for a vault-wide audit.
---

# Tag Taxonomy

A note's tag line answers six questions in a fixed order: **what field**, **what sub-area**,
**which mechanisms**, **which named technologies**, **what shape**, and **what state**. The approved
vocabulary lives in [taxonomy.md](references/taxonomy.md). Read it before you assign, change, or
audit a single tag. For a vault-wide audit, also read [audit.md](references/audit.md).

This skill operates under `AGENTS.md`, which wins on conflict.

## Quick Card

```yaml
tags: [<domain>, <topic…>, <concept…>, <tech…>, <type>, <lifecycle>, <user…>]
```

| Facet       | Count | Answers                                        | Vocabulary |
| ----------- | ----- | ---------------------------------------------- | ---------- |
| `domain`    | 1     | Which field? (also decides the folder)         | Closed     |
| `topic`     | 1–3   | Which sub-area of that field?                  | Closed     |
| `concept`   | 0–4   | Which mechanisms or ideas does it explain?     | Closed     |
| `tech`      | 0–4   | Which named products, platforms, or standards? | **Open**   |
| `type`      | 0–1   | Overview, comparison, or how-to?               | Closed     |
| `lifecycle` | 0–1   | Stub, or needs review?                         | Closed     |

- **Mandatory set:** one `domain` + at least one `topic`. A substantive (non-`stub`) note also needs
  at least one `concept` **or** `tech` tag; `overview` hubs are exempt.
- **Ceiling:** 10 tags in total, user tags included.
- **Format:** always an inline YAML list — `tags: [databases, transactions, acid]`. Never a block
  list (`tags:` followed by `- item` lines), never `#`, never `/` nesting, lowercase `kebab-case`
  spelled exactly as its facet table writes it.

### Which facet does a candidate belong to?

Ask in this order and stop at the first yes:

1. Is it a named product, platform, service, or standard? → `tech`
2. Is it the note's shape (hub, contrast, procedure)? → `type`
3. Is it the note's state (placeholder, unverified)? → `lifecycle`
4. Is it a sub-area *within this note's field*? → `topic`
5. Is it a mechanism or idea that would recur in another field? → `concept`
6. None of the above → it is probably the note's title or a banned general word. Leave it off.

## Tagging a Note

Run this every time you create or update a note. Tag what the body actually explains, not what the
filename suggests.

1. **Read** [taxonomy.md](references/taxonomy.md).
2. **Read the neighbours.** Grep `^tags:` across the target folder (and any tech subfolder) and
   look at how sibling notes are tagged. Match their choices unless this note genuinely differs.
   This is the cheapest way to stay consistent.
3. **Domain** — the single field. Use the *Excludes* column to break ties. If it still splits two
   ways, the note covers two concepts and should be split (`AGENTS.md` §3, one concept per note).
4. **Topic** — the most specific approved topic that fits. Add a second or third only while each
   narrows the note further. If nothing fits, propose a new tag (below); never leave the note
   topicless or force a poor match.
5. **Concept** — mechanisms the note *explains*, not ones it mentions in passing.
6. **Tech** — every product or standard the note is substantively about, including the one in its
   own title. A product mentioned once as an example does not count.
7. **Type** — `overview` for a hub whose main job is routing to child notes, `comparison` when the
   subject *is* the difference, `how-to` for a procedure. Ordinary explanatory notes take none.
8. **Lifecycle** — `stub` for a placeholder; `needs-review` exactly when the note has a non-empty
   `## Open Questions & Disagreements` section.
9. **Carry over** existing user tags. Add new ones only when the user asks for them by name.
10. **File it.** The `domain` tag decides the folder (the *Folder* column of the domain table). A
    note in a tech subfolder (`dbt/`, `kafka/`, …) must carry that subfolder's `tech` tag.
    Changing the domain tag of an existing note means moving the file, so follow the rename
    procedure in `AGENTS.md` §7.
11. **Verify** against the Definition of Done below.

### Worked examples

| Note                                     | Tags                                                                               | Why                                                                       |
| ---------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `acid.md`                                | `[databases, transactions, concurrency-control, consistency-models]`               | Two mechanisms it genuinely explains; no product involved                 |
| `cap_theorem.md`                         | `[databases, distributed-systems, consistency-models, fault-tolerance, replication]` | Multi-node topic; three distinct mechanisms                             |
| `bloom_filter.md`                        | `[data-structures, indexing, probabilistic-structures]`                            | Vendor-neutral structure theory, so no `tech`                             |
| `dbt_bigquery_adapter.md`                | `[data-engineering, dbt, bigquery]`                                                | Substance is product behaviour, so `tech` carries it instead of `concept` |
| `deploy_dbt_cloud_run_github_actions.md` | `[data-engineering, deployment, ci-cd, dbt, cloud-run, github-actions, how-to]`    | A procedure spanning three named technologies                             |
| `semantic_layer_vs_ontology_layer.md`    | `[data-architecture, data-modeling, metric-definition, knowledge-graph, comparison]` | The subject *is* the contrast                                           |
| `data_structures_algorithms.md`          | `[data-structures, indexing, overview]`                                            | Hub note, so exempt from the concept-or-tech rule                         |
| `fix_protocol.md`                        | `[software-architecture, api-protocols, compatibility-contracts, fix-protocol]`    | `tech` repeats the title on purpose, to cluster the protocol's notes      |

## Core Rules

1. **Closed facets are closed.** Every `domain`, `topic`, `concept`, `type`, and `lifecycle` tag
   appears verbatim in [taxonomy.md](references/taxonomy.md). If nothing fits, propose an addition
   (below). Never invent one inline.
2. **`tech` is open.** Add a new product name on first use without approval. Use the canonical
   lowercase name (`bigquery`, not `google-bigquery`), never a version (`dbt`, not `dbt-1-8`), never
   a category (`warehouse` is not a product). Add it to the seed table once a second note uses it.
3. **Every tag must exclude something.** A tag earns its place only if it says something the note's
   folder, title, and other tags do not. If it would fit almost every note, or you cannot say in one
   sentence what it excludes, leave it off. The Banned Tags table lists the usual offenders. This
   binds user tags too: if the user asks for a banned tag, say so and propose a specific
   alternative before writing.
4. **Tag the subject, not the title.** A closed-facet tag that restates the filename adds nothing.
   The exception is `tech`: `dbt.md` carries `dbt` so it clusters with its adapter notes.
5. **The table is the spelling.** Copy tags exactly, number included. The vocabulary holds both
   `data-quality` and `databases`, so never "fix" a plural by rule of thumb.
6. **Concept tags are shared vocabulary.** A concept already in the taxonomy is usable even if only
   one note carries it so far. The "two or more notes" bar applies when *proposing* a new concept.
7. **Lifecycle tags track reality.** Remove `stub` the moment the note has real sections. Keep
   `needs-review` on a note exactly as long as its `## Open Questions & Disagreements` section is
   non-empty; remove it as soon as the section is empty.
8. **User tags are preserved.** Never strip one in an update or audit. They must still be
   `kebab-case`, must not be banned, must not duplicate a facet tag, come last, and count toward the
   ceiling.
9. **Respect hand edits; don't fight them.** If the user has left a note's tags in an invalid state
   (e.g. removed `needs-review` while open questions remain), say so in one line of your report and
   leave the tag as they set it. Do not silently revert it. Fix only what your own request touched.

## Common Mistakes

| Mistake                                                         | Seen as                                     | Fix                                                        |
| --------------------------------------------------------------- | ------------------------------------------- | ---------------------------------------------------------- |
| Block-list frontmatter                                          | `tags:` then `  - devops` lines             | Rewrite as one inline list                                 |
| A tag that restates the title                                   | `sanity-check` on `data_sanity_check.md`    | Drop it; the title already says it                         |
| A category posing as a product                                  | `warehouse`, `cloud`, `orchestrator`        | The product's name, or the matching `topic`                |
| A version-pinned tech tag                                       | `dbt-1-8`, `python-3-12`                    | Unversioned tag; put the version in the body               |
| `overview` on a single-product note that links to no child notes | a product intro tagged `overview`           | Drop `overview`; give it `concept`/`tech` tags instead     |
| A lifecycle tag that no longer matches the note                 | `stub` on a full page; `needs-review` with no open questions | Remove the tag                            |
| A topic from the wrong domain to fill a gap                     | a vulnerability scanner tagged `data-security` | Propose a fitting topic instead of forcing one          |

## Adding or Retiring a Tag

A `tech` tag needs no ceremony. Every **closed-facet** tag changes the vocabulary and needs explicit
user approval. Propose one only when:

- it applies to **three or more** existing or imminent notes (`domain`, `topic`, `type`), or **two
  or more** (`concept`), **and**
- no approved tag or combination already covers it, **and**
- it fits cleanly into exactly one facet.

State the tag, its facet, a one-line **Covers** and **Excludes**, and the notes it would apply to. On
approval, insert it alphabetically into the right table in [taxonomy.md](references/taxonomy.md)
and apply it. A new `domain` tag also needs its folder under `wiki/concepts/`, which is a structure
change that requires approval (`AGENTS.md` §1).

**Logging:** the edit to `taxonomy.md` is outside `wiki/`, so it gets no log entry of its own
(`AGENTS.md` §1.5). Name it in one clause of the wiki entry for the note that needed the tag, e.g.
"New `retrieval-augmentation` concept tag approved and added to the taxonomy."

**Retiring a tag** works the same way in reverse: retag every affected note, then add a row to the
Retired Tags table naming the replacement and the reason. That row is the only lasting record of
*why*.

## Definition of Done

- [ ] `tags` is a single inline list, in facet order, with no more than 10 entries.
- [ ] Exactly one `domain` and 1–3 `topic` tags; every closed-facet tag appears verbatim in [taxonomy.md](references/taxonomy.md).
- [ ] A substantive note has at least one `concept` or `tech` tag (`overview` hubs exempt), and every technology it is substantively about is tagged.
- [ ] Every `tech` tag is a canonical, version-free product or standard name.
- [ ] The note's folder matches its `domain` tag, and a note in a tech subfolder carries that subfolder's `tech` tag.
- [ ] `stub` appears only on genuine placeholders; `needs-review` matches a non-empty `## Open Questions & Disagreements` section (or the mismatch is a user hand edit you reported).
- [ ] User tags are preserved and listed last; no banned tag was added.
- [ ] `updated` was bumped from the real clock; the wiki log entry names any vocabulary change in one clause.
- [ ] Any new closed-facet tag was approved and written into [taxonomy.md](references/taxonomy.md); any `tech` tag now used by two notes has a seed-table row.
