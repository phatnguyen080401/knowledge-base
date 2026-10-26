# Obsidian Syntax Reference

The syntax every note body must pass. The vault is an Obsidian vault rooted at the repository
folder, and every note must render cleanly there. Obsidian extends CommonMark and GFM with
wikilinks, embeds, callouts, and more; this file says which of those extensions the vault uses, in
what exact form, and which it bans. Writers read it during [`wiki-create`](../../wiki-create/SKILL.md)
and [`wiki-ingest`](../../wiki-ingest/SKILL.md); the [lint pass](../SKILL.md) enforces it with the
greps under [Checks](#checks). Standard Markdown is assumed knowledge.

`AGENTS.md` wins on conflict. This file covers the **body** of a note.
Frontmatter belongs to `AGENTS.md` §3 and tags to [`tag-taxonomy`](../../tag-taxonomy/SKILL.md);
nothing here adds a property or a tag form.

## Internal Links

Every link to a note uses the full vault-relative path from `concepts/` and is always piped
(`AGENTS.md` §2):

```markdown
[[concepts/data_governance/data_quality|Data Quality]]                          Note
[[concepts/software_architecture/concurrency_and_parallelism#Concurrency Control|Concurrency Control]]   Heading
[[concepts/data_governance/data_quality#^six-dimensions|the six dimensions]]    Block
```

- **Path form.** Write `concepts/<folder>/[<tech_subfolder>/]<file>` with no `.md`. Never the
  shortest form (`[[data_quality]]`), never a `wiki/` prefix, never `[text](note.md)`. The vault
  root is the repository root, and Obsidian resolves `concepts/…` by unique path suffix.
- **Headings.** Copy the heading text exactly, including case and punctuation. If you rename a
  heading, grep for `#<old heading>` across `wiki/` and fix every link to it.
- **Same-note links** use the note's own full path, piped:
  `[[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions#Scheduling the Job|Scheduling the Job]]`.
  Never a bare `[[#Heading]]`.
- **Block IDs** only when no heading fits. Append ` ^kebab-id` to the paragraph, or put `^kebab-id`
  on its own line after a list, table, or quote.
- **Code is not a link.** `[[ … ]]` inside a code fence or inline code is code (bash tests, for
  example) and is never rewritten.
- **Renames are manual.** Obsidian updates links only for renames made inside the app. An agent's
  rename is a file move, so follow `AGENTS.md` §7 and repoint every inbound link yourself.

External URLs use standard Markdown links: `[dbt docs](https://docs.getdbt.com)`.

## Callouts

```markdown
> [!warning] The baseline advances even on failure
> The manifest is uploaded before the run's exit code is checked, so …
```

Always give a title; keep the body to a short paragraph or list; never nest. Use them for what a
reader must not miss, not as decoration. Types and their uses in this vault:

| Type        | Use for                                                        |
| ----------- | -------------------------------------------------------------- |
| `warning`   | A pitfall, a footgun, or a rule that breaks things if ignored  |
| `important` | The single idea the rest of the section depends on             |
| `tip`       | A non-obvious technique or shortcut                            |
| `info`      | Scope or framing for the note, e.g. "template, not a runbook"  |
| `note`      | An aside, a correction, or marked inference (below)            |
| `example`   | A worked example set apart from the explanation                |

**Marked inference** (`AGENTS.md` §1.9) uses a `note` callout titled `Inference, …`, e.g.
`> [!note] Inference, not repository fact`. A callout never replaces
`## Open Questions & Disagreements`: an extrapolation or a source conflict is also listed there,
and that section drives the `needs-review` tag. See [callouts.md](callouts.md) for the
full type list and folding.

## Embeds

Only images and PDFs are embedded, and only from `raw/assets/`, named `snake_case` with the
related concept as prefix (`AGENTS.md` §2):

```markdown
![[raw/assets/data_quality_dimensions.png|600]]

The six dimensions, grouped by whether they are checked per record or per dataset.
```

Follow every embed with a sentence that says what it shows, so the note still reads without the
image (on GitHub or in a terminal). Size, PDF page, and other options are in
[embeds.md](embeds.md).

## Diagrams, Math, and Highlights

- **Mermaid** in a ` ```mermaid ` fence for flows, sequences, and architecture. Label line breaks
  may use `<br/>` inside the fence; that is the only HTML allowed anywhere.
- **Math** with `$…$` inline and `$$…$$` on their own lines for display formulas. Use it for real
  formulas (false-positive rates, quorum sizes), not for styling a variable name, which takes
  inline code.
- **Highlights** `==text==` at most once or twice per note, for a value the reader must remember.
- **Task lists** `- [ ]` only in `how-to` notes, for steps the reader ticks off.

## Banned in This Vault

| Obsidian syntax                                      | Why it is banned                                                           | Use instead                                              |
| ---------------------------------------------------- | -------------------------------------------------------------------------- | -------------------------------------------------------- |
| Inline `#tag` or nested `#tag/sub`                   | Tags live only in the frontmatter list (`tag-taxonomy`)                    | The inline `tags: [a, b]` list                           |
| Block-list properties (`tags:` then `- a`)           | `AGENTS.md` §3 requires one-line lists                                     | `tags: [a, b]`, `sources: [x, "https://…"]`              |
| `aliases`, `date`, `status`, `cssclasses`, any other extra property | The schema is `title`, `tags`, `sources`, `created`, `updated` | An acronym goes in `title`: `Master Data Management (MDM)` |
| `%%comment%%`                                        | Hidden in reading view, so unreviewable content                            | `## Open Questions & Disagreements`, or delete it        |
| Footnotes `[^1]`, `^[inline]`                        | Citations live in `sources` and `## References`                            | `sources` frontmatter plus a `## References` bullet      |
| Note transclusion `![[concepts/…]]`                  | Pages must stand alone; one concept per note                               | A piped wikilink, with a sentence saying why it matters  |
| `query` code blocks, `![[*.base]]` embeds            | Output depends on the vault state, not the note                            | A written list of piped wikilinks                        |
| `[text](concepts/x.md)` to a note                    | `AGENTS.md` §2 link form; the lint pass parses only wikilinks              | `[[concepts/x\|Text]]`                                   |
| Raw HTML (`<br>`, `<details>`, `<sup>`, …)           | `AGENTS.md` §3: prose and bullets only                                     | Markdown; `<br/>` only inside a Mermaid fence            |
| Bare `[[Note]]` or `[[#Heading]]`                    | `AGENTS.md` §2: full path, always piped                                    | `[[concepts/<folder>/<file>#Heading\|Text]]`             |

## Example

````markdown
---
title: Bloom Filter
tags: [data-structures, indexing, probabilistic-structures]
created: 2026-10-26 09:14:02
updated: 2026-10-26 09:14:02
---

# Bloom Filter

A space-efficient probabilistic set that answers "definitely not present" or "possibly present",
used as an index shortcut in [[concepts/data_structures/data_structures_algorithms|Data Structures and Algorithms]].

## Why It Matters

> [!important] No false negatives
> A negative answer is always correct, so a miss can skip the disk read entirely.

## False-Positive Rate

With $m$ bits, $k$ hash functions, and $n$ inserted keys:

$$
p \approx \left(1 - e^{-kn/m}\right)^k
$$

## Related Concepts

- [[concepts/data_structures/lsm_tree#The Read Path|LSM Tree read path]] — checks a Bloom filter per SSTable before reading it
````

## Checks

- [ ] Every internal link is `[[concepts/…|Text]]`: full path, piped, and the target file (and
      heading, if any) exists.
- [ ] Callouts have a type from the table and a title; marked inference is also listed under
      `## Open Questions & Disagreements`.
- [ ] Embeds point to existing `raw/assets/` files and are followed by a describing sentence.
- [ ] Nothing from the banned table appears outside code fences.

Run on each touched note; hits inside code fences are not defects:

```bash
grep -noE '\[\[[^]|]+\]\]' <note>                       # unpiped links
grep -noE '\]\([^)]*\.md(#[^)]*)?\)' <note>             # Markdown links to notes
grep -nE '(^|\s)#[A-Za-z][-_/A-Za-z0-9]*' <note>        # inline tags
grep -nE '%%|\[\^|!\[\[concepts/|\.base\]\]|^```query' <note>   # comments, footnotes, transclusion, dynamic embeds
grep -nE '^(aliases|date|status|cssclasses):' <note>    # extra properties
grep -nE '</?(br|div|span|sup|sub|details|summary|img|a|p|b|i|u|font|iframe)[ />]' <note>   # raw HTML (allowed only inside mermaid fences)
```
