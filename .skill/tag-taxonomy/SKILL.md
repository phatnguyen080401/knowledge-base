---
name: tag-taxonomy
description: Choose a wiki note's tags across six facets (domain, topic, concept, tech, type, lifecycle) and the folder its domain tag fixes. Use on every note create, update, move, or filing; when the user says "fix my tags", "normalize tags", "clean up tags", "tag audit", "retag", "what tags should I use", "tag taxonomy", or "my tags are a mess"; asks how notes are classified; or wants to add or retire a tag.
argument-hint: "[scope]"
---

# Tag Taxonomy

A note's tag line answers six questions in a fixed order: what field, what sub-area, which
mechanisms, which named technologies, what shape, and what state. The vocabulary is in
[taxonomy.md](references/taxonomy.md). For an audit (`/tag-taxonomy [scope]`), also read
[audit.md](references/audit.md) and limit it to the given folder or note, if any.

## Quick Card

```yaml
tags: [<domain>, <topic…>, <concept…>, <tech…>, <type>, <lifecycle>, <user…>]
```

| Facet | Count | Answers | Vocabulary |
| --- | --- | --- | --- |
| `domain` | 1 | Which field? (also decides the folder) | Closed |
| `topic` | 1–3 | Which sub-area of that field? | Closed |
| `concept` | 0–4 | Which mechanisms or ideas does it explain? | Closed |
| `tech` | 0–4 | Which named products, platforms, or standards? | **Open** |
| `type` | 0–1 | Overview, comparison, or how-to? | Closed |
| `lifecycle` | 0–1 | Stub, or needs review? | Closed |

- **Mandatory set:** one `domain` + at least one `topic`. A substantive (non-`stub`) note also needs
  at least one `concept` **or** `tech` tag; `overview` hubs are exempt.
- **Ceiling:** 10 tags in total, user tags included.
- **Form:** an inline list (`AGENTS.md` §3), lowercase `kebab-case` spelled exactly as its facet
  table writes it; never `#`, never `/` nesting.

### Which facet does a candidate belong to?

Ask in this order and stop at the first yes:

1. A named product, platform, service, or standard? → `tech`
2. The note's shape (hub, contrast, procedure)? → `type`
3. The note's state (placeholder, unverified)? → `lifecycle`
4. A sub-area *within this note's field*? → `topic`
5. A mechanism or idea that would recur in another field? → `concept`
6. None of the above → probably the note's title or a banned general word. Leave it off.

## Tagging a Note

Run this on every create or update. Tag what the body explains, not what the filename suggests.

1. **Read** [taxonomy.md](references/taxonomy.md).
2. **Read the neighbours.** Grep `^tags:` across the target folder (and any subfolder) and
   match the siblings' choices unless this note genuinely differs.
3. **Domain** — the single field; the *Excludes* column breaks ties. If it still splits two ways,
   the note covers two concepts and should be split.
4. **Topic** — the most specific approved topic. Add a second or third only while each narrows the
   note further. If nothing fits, propose a new tag (below); never force a poor match.
5. **Concept** — mechanisms the note *explains*, not ones it mentions in passing.
6. **Tech** — every product or standard the note is substantively about, including the one in its
   own title. A product mentioned once as an example does not count.
7. **Type** — per the type table; most notes take none.
8. **Lifecycle** — `stub` and `needs-review` per `AGENTS.md` §3.
9. **Carry over** existing user tags. Add new ones only when the user asks for them by name.
10. **File it.** The *Folder* column of the domain table decides the folder; a domain change is a
    move ([`wiki-maintain`](../wiki-maintain/SKILL.md)).
11. **Verify** against the Definition of Done below.

### Worked examples

| Note | Tags | Why |
| --- | --- | --- |
| `acid.md` | `[databases, transactions, concurrency-control, consistency-models]` | Two mechanisms it genuinely explains; no product involved |
| `bloom_filter.md` | `[data-structures, indexing, probabilistic-structures]` | Vendor-neutral structure theory, so no `tech` |
| `deploy_dbt_cloud_run_github_actions.md` | `[data-engineering, deployment, ci-cd, dbt, cloud-run, github-actions, elementary, how-to]` | A procedure spanning four named technologies |
| `semantic_layer_vs_ontology_layer.md` | `[data-architecture, data-modeling, metric-definition, knowledge-graph, comparison]` | The subject *is* the contrast |

## Core Rules

1. **Closed facets are closed.** Every `domain`, `topic`, `concept`, `type`, and `lifecycle` tag
   appears verbatim in [taxonomy.md](references/taxonomy.md). If nothing fits, propose an addition
   (below); never invent one inline. A tag the user names that is in no table is a user tag (rule 8).
2. **`tech` is open.** Add a product on first use without approval, by its canonical lowercase
   name as the vendor writes it (`bigquery`, not `google-bigquery`), never a version (`dbt`, not
   `dbt-1-8`), never a category (`warehouse`, `cloud`). Add a seed-table row once a second note
   uses it.
3. **Every tag must exclude something.** A tag earns its place only if it says something the note's
   folder, title, and other tags do not. If it would fit almost every note, or you cannot say in one
   sentence what it excludes, leave it off; taxonomy.md's Banned table lists the usual offenders.
   This binds user tags too: if the user asks for a banned tag, say so and propose a specific
   alternative before writing.
4. **Tag the subject, not the title.** A closed-facet tag that restates the filename adds nothing
   (`sanity-check` on `data_sanity_check.md`). The exception is `tech`: `dbt.md` carries `dbt` so
   it clusters with its adapter notes.
5. **The table is the spelling.** Copy tags exactly, number included. The vocabulary holds both
   `data-quality` and `databases`, so never "fix" a plural by rule of thumb.
6. **Concept tags are shared vocabulary.** A concept already in the taxonomy is usable even if only
   one note carries it. The two-note bar applies when *proposing* a new concept.
7. **Lifecycle tags track reality**, per `AGENTS.md` §3.
8. **User tags are preserved.** Never strip one in an update or audit. They must still be
   `kebab-case`, must not be banned, must not duplicate a facet tag, come last, and count toward the
   ceiling. Before keeping an unknown tag on an existing note as a user tag, check audit.md's
   Retired table and Typo class.
9. **Respect hand edits; don't fight them.** If the user has left a note's tags in an invalid state
   (e.g. removed `needs-review` while open questions remain), say so in one line of your report and
   leave the tag as they set it. Fix only what your own request touched.

## Adding or Retiring a Tag

A `tech` tag needs no ceremony. A **closed-facet** tag changes the vocabulary and needs explicit
user approval. Propose one only when it applies to **three or more** existing or imminent notes
(**two** for a `concept`), no approved tag or combination already covers it, and it fits cleanly
into exactly one facet. State the tag, its facet, a one-line **Covers** and **Excludes**, and the
notes it would apply to. On approval, insert it alphabetically into the right table in
[taxonomy.md](references/taxonomy.md) and apply it. A new `domain` also needs a folder, a structure
change (`AGENTS.md` §1).

Retiring a tag: follow [audit.md](references/audit.md) §5.

## Definition of Done

- [ ] One inline list in facet order, at most 10 tags: exactly one `domain`, 1–3 `topic`, and every closed-facet tag verbatim in taxonomy.md.
- [ ] A substantive note has a `concept` or `tech` tag (`overview` exempt), and every technology it is substantively about is tagged by its canonical, version-free name.
- [ ] The folder matches the `domain` tag; a note in a tech subfolder carries that subfolder's `tech` tag.
- [ ] User tags are preserved and last; no banned tag was added; any new closed-facet tag was approved and written into taxonomy.md; a `tech` tag now on two notes has a seed row.
