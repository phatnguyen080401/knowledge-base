# Obsidian Syntax Reference

Body syntax for every note; frontmatter is `AGENTS.md` §3 and tags are
[`tag-taxonomy`](../../tag-taxonomy/SKILL.md). Every writer follows it, and the
[lint pass](../SKILL.md) enforces it with the greps under [Checks](#checks).

## Internal Links

Every link to a note uses the full vault-relative path from `concepts/` and is always piped:

```markdown
[[concepts/data_governance/data_quality|Data Quality]]                          Note
[[concepts/software_architecture/concurrency_and_parallelism#Concurrency Control|Concurrency Control]]   Heading
[[concepts/data_governance/data_quality#^six-dimensions|the six dimensions]]    Block
```

- **Path form.** `concepts/<folder>/[<tech_subfolder>/]<file>` with no `.md`. Never the shortest
  form (`[[data_quality]]`), never a `wiki/` prefix, never `[text](note.md)`. The vault root is the
  repository root, and Obsidian resolves `concepts/…` by unique path suffix.
- **Tables.** Inside a table cell, escape the pipe: `[[concepts/x/y\|Text]]`.
- **Headings.** Copy the heading text exactly, including case and punctuation. Renaming a heading
  means fixing every `#<old heading>` link to it across `wiki/`.
- **Same-note links** use the note's own full path, piped; never a bare `[[#Heading]]`.
- **Block IDs** only when no heading fits: append ` ^kebab-id` to the paragraph, or put `^kebab-id`
  on its own line after a list, table, or quote.
- **Code is not a link.** `[[ … ]]` inside a code fence or inline code is code and is never
  rewritten.

External URLs use standard Markdown links: `[dbt docs](https://docs.getdbt.com)`.

## Callouts

```markdown
> [!warning] The baseline advances even on failure
> The manifest is uploaded before the run's exit code is checked, so …
```

Always give a title (a title-only callout is fine for a one-line warning); keep the body to a short
paragraph or list; never nest. Use them for what a reader must not miss, not as decoration. Fold
(`> [!example]-`) only long optional material such as a worked example, and never a `warning`. The
definition paragraph and open questions are never callouts. Only these types:

| Type | Use for |
| --- | --- |
| `warning` | A pitfall, a footgun, or a rule that breaks things if ignored |
| `important` | The single idea the rest of the section depends on |
| `tip` | A non-obvious technique or shortcut |
| `info` | Scope or framing for the note, e.g. "template, not a runbook" |
| `note` | An aside, a correction, or marked inference (below) |
| `example` | A worked example set apart from the explanation |

**Marked inference** (`AGENTS.md` §1.9) uses a `note` callout titled `Inference, …`, e.g.
`> [!note] Inference, not repository fact`. It is also listed under
`## Open Questions & Disagreements`, which drives the `needs-review` tag.

## Embeds

Only images and PDFs, only from `raw/assets/`, named `snake_case` with the related concept as
prefix (`AGENTS.md` §2). Never overwrite an existing asset; pick a more specific name.

```markdown
![[raw/assets/data_quality_dimensions.png|600]]

The six dimensions, grouped by whether they are checked per record or per dataset.
```

Follow every embed with a sentence saying what it shows, so the note reads without the image.
Size with `|600` or `|600x400` (600 or less for diagrams). Embed a PDF page (`#page=3`) only when
it carries a figure or table the note discusses; the PDF is still cited in `sources`.

## Diagrams, Math, and Highlights

- **Mermaid** in a ` ```mermaid ` fence for flows, sequences, and architecture. Label line breaks
  may use `<br/>` inside the fence; that is the only HTML allowed anywhere.
- **Math** with `$…$` inline and `$$…$$` on their own lines for display formulas. Use it for real
  formulas (false-positive rates, quorum sizes), not for styling a variable name, which takes
  inline code.
- **Highlights** `==text==` at most once or twice per note, for a value the reader must remember.
- **Task lists** `- [ ]` only in `how-to` notes, for steps the reader ticks off.

## Banned in This Vault

| Banned | Use instead |
| --- | --- |
| Inline `#tag` or nested `#tag/sub` | The frontmatter `tags` list |
| Block-list properties (`tags:` then `- a`) | `tags: [a, b]`, `sources: [x, "https://…"]` |
| `aliases`, `date`, `status`, `cssclasses`, any other extra property | The §3 schema only; an acronym goes in `title`: `Master Data Management (MDM)` |
| `%%comment%%` | `## Open Questions & Disagreements`, or delete it |
| Footnotes `[^1]`, `^[inline]` | `sources` frontmatter plus a `## References` bullet |
| Note transclusion `![[concepts/…]]` | A piped wikilink, with a sentence saying why it matters |
| `query` code blocks, `![[*.base]]` embeds | A written list of piped wikilinks |
| External images `![alt](https://…)` | Save the file to `raw/assets/` and embed it |
| Raw HTML (`<br>`, `<details>`, `<sup>`, …) | Markdown; `<br/>` only inside a Mermaid fence |

## Checks

- [ ] Every internal link is `[[concepts/…|Text]]`: full path, piped, and the target file (and
      heading, if any) exists.
- [ ] Callouts have a type from the table above and a title; marked inference is also listed under
      `## Open Questions & Disagreements`.
- [ ] Embeds point to existing `raw/assets/` files and are followed by a describing sentence.
- [ ] Nothing from the banned table appears outside code fences.

Run on each touched note; hits inside code fences are not defects:

```bash
grep -noE '\[\[[^]|]+\]\]' <note>                       # unpiped links
grep -noE '\]\([^)]*\.md(#[^)]*)?\)' <note>             # Markdown links to notes
grep -nE '(^|\s)#[A-Za-z][-_/A-Za-z0-9]*' <note>        # inline tags
grep -nE '%%|\[\^|!\[\[concepts/|\.base\]\]|^```query' <note>   # comments, footnotes, transclusion, dynamic embeds
grep -nE '!\[[^]]*\]\(https?://' <note>                 # external images
grep -nE '^(aliases|date|status|cssclasses):' <note>    # extra properties
grep -nE '</?(br|div|span|sup|sub|details|summary|img|a|p|b|i|u|font|iframe)[ />]' <note>   # raw HTML (allowed only inside mermaid fences)
```
