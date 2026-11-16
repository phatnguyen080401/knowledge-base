---
name: tag-taxonomy
description: Choose a wiki note's tags and the folder they fix. Use when writing a new note or changing what a note covers; when the user says "fix my tags", "clean up tags", "tag audit", or "what tags should I use", asks how notes are classified, or wants to add or retire a tag.
argument-hint: "[scope]"
---

# Tag Taxonomy

Tags are the only index across folders (wiki-query and wiki-lint search them), so a loose tag pulls
unrelated notes together. The vocabulary is [taxonomy.md](references/taxonomy.md). For an audit
(`/tag-taxonomy [scope]`), also read [audit.md](references/audit.md), limited to the scope given.

## Quick Card

```yaml
tags: [<domain>, <topic…>, <concept…>, <tech…>, <type>, <lifecycle>, <user…>]
```

| Facet | Count | Vocabulary |
| --- | --- | --- |
| `domain` | 1, decides the folder | Closed |
| `topic` | 1–3 | Closed |
| `concept` | 0–4 | Closed |
| `tech` | 0–4 | **Open** |
| `type` | 0–1: `comparison` (subject *is* the contrast), `how-to` (procedure to execute), `overview` (hub routing to child notes) | Closed |
| `lifecycle` | 0–1: `stub` (no body beyond the definition), `needs-review` (exactly while Open Questions is non-empty) | Closed |

- **Mandatory:** one `domain` and at least one `topic`; a non-`stub`, non-`overview` note also needs
  a `concept` or `tech` tag. At most 10 tags, user tags included.
- **Form:** inline list (`AGENTS.md` §3), `kebab-case` spelled exactly as taxonomy.md writes it,
  never `#` or `/`.

**Which facet?** Stop at the first yes: a named product, platform, service, or standard → `tech`;
the note's shape → `type`; its state → `lifecycle`; a named mechanism, technique, structure, or
model whose workings the note explains (`concurrency-control`, `linear-regression`) → `concept`,
whether or not it recurs across fields; the area of practice it sits in, broad enough to hold
several concepts (`transactions`, `model-training`) → `topic`; none → leave it off.

## Tagging a Note

Tag what the body explains, not what the filename suggests. On an existing note, a link, a Related
Concepts bullet, or a bumped `updated` needs no re-tagging; otherwise re-check only the facets the
change touches.

1. **Neighbours.** Grep `^tags:` across the target folder for candidates. A sibling's tag is
   evidence, not authority: reuse it only once its row fits this note, or one filler tag spreads to
   every new note in the folder.
2. **Vocabulary, cheaply.** Read only the Index at the top of taxonomy.md (Read with `limit: 20`),
   then grep the rows of your candidates (`grep -E '^\| `(tag-a|tag-b)` ' <taxonomy.md>`) for
   Covers and Excludes. Read the `domain` table only for a new note or a domain change, and a whole
   facet table only when nothing fits and you may propose a tag. Audits read the file whole.
3. **Domain** — the single field; Excludes breaks ties. Still split two ways → the note covers two
   concepts and should be split.
4. **Topic** — the most specific one whose Covers describes this note; a second or third only while
   each narrows it further. Nothing fits → propose a new tag ([audit.md](references/audit.md) §8);
   never borrow a poor match to fill the mandatory set.
5. **Concept** — mechanisms the note *explains*, not ones it mentions in passing.
6. **Tech** — every product or standard the note is substantively about, including its own title's;
   one mention as an example does not count.
7. **Type, lifecycle** — per the Quick Card; most notes take neither.
8. **User tags** — keep them, last; add one only when the user names it
   ([audit.md](references/audit.md) §2 for unknown tags and hand edits).
9. **File it.** The domain's folder is its tag in `snake_case`; a domain change is a move
   ([`wiki-maintain`](../wiki-maintain/SKILL.md)).

| Note | Tags | Why |
| --- | --- | --- |
| `acid.md` | `[databases, transactions, concurrency-control, consistency-models]` | Two mechanisms it explains; no product |
| `deploy_dbt_cloud_run_github_actions.md` | `[data-engineering, deployment, ci-cd, dbt, cloud-run, github-actions, elementary, how-to]` | A procedure spanning four products |

## Core Rules

1. **Closed facets are closed.** Every non-`tech` tag appears verbatim in taxonomy.md; otherwise
   propose it (audit.md §8), never invent it inline. A tag the user names that is in no table is a
   user tag.
2. **`tech` is open.** Add a product on first use by its canonical lowercase name
   (`bigquery`, not `google-bigquery`), never a version (`dbt-1-8`) or a category (`warehouse`).
   Once a second note uses it, add a seed row and its Index entry.
3. **Every tag must exclude something** the folder, title, and other tags don't already say. Banned
   for that reason (taxonomy.md's Banned table): generic words (`data`, `tech`, `misc`, `note`,
   `concept`), praise (`important`), workflow (`todo`, `wip`, `draft` → use lifecycle), categories
   (`cloud`, `tool`, `warehouse`, `architecture`, `programming`), and versioned names. This binds
   user tags too: say so and propose an alternative.
4. **Tag the subject, not the title.** A closed-facet tag restating the filename adds nothing
   (`sanity-check` on `data_sanity_check.md`); `tech` is exempt (`dbt.md` carries `dbt`).
5. **The table is the spelling.** Copy tags exactly; never "fix" a plural by rule of thumb.

## Definition of Done

- [ ] Facet order, counts, and mandatory set per the Quick Card; every closed-facet tag verbatim in taxonomy.md.
- [ ] The folder matches the domain; a note in a tech subfolder carries that subfolder's `tech` tag.
- [ ] User tags kept and last; no banned tag; a new closed-facet tag was approved and added (row and Index); a `tech` tag on two notes has a seed row.
