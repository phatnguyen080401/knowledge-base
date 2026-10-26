# Callouts Reference

The vault conventions (which type for what, titles required, marked inference) are in
[obsidian-syntax.md](obsidian-syntax.md#callouts). This file is the syntax reference.

## Syntax

```markdown
> [!warning] Title
> Body: a short paragraph or list. Every line starts with `>`.
```

- The type is case-insensitive; write it lowercase.
- A title is required in this vault. A title-only callout (no body lines) is allowed for a one-line
  warning.
- Wikilinks, inline code, emphasis, and math work inside the body. Code fences work too, with each
  fence line prefixed by `> `.

## Folding

```markdown
> [!example]- Collapsed by default
> Hidden until expanded.

> [!example]+ Expanded by default
> Visible, but can be collapsed.
```

Fold only long, optional material such as a worked example or a full config listing. Never fold a
`warning`: the reader must see it.

## Types

Aliases render identically to their type; write the type name, not the alias.

| Type        | Aliases                  | Renders as         |
| ----------- | ------------------------ | ------------------ |
| `note`      | —                        | Blue, pencil       |
| `abstract`  | `summary`, `tldr`        | Teal, clipboard    |
| `info`      | —                        | Blue, info         |
| `todo`      | —                        | Blue, checkbox     |
| `tip`       | `hint`, `important`      | Cyan, flame        |
| `success`   | `check`, `done`          | Green, checkmark   |
| `question`  | `help`, `faq`            | Yellow, question   |
| `warning`   | `caution`, `attention`   | Orange, warning    |
| `failure`   | `fail`, `missing`        | Red, X             |
| `danger`    | `error`                  | Red, zap           |
| `bug`       | —                        | Red, bug           |
| `example`   | —                        | Purple, list       |
| `quote`     | `cite`                   | Gray, quote        |

`important` is the one alias the vault writes by name, because existing notes use it for the key
idea of a section. Unknown types render as `note`; custom CSS callouts are not used, since
`.obsidian/` snippets do not travel with the notes.

## Do Not

- Nest callouts (`> > [!note]`).
- Use `question` or `todo` for open questions. Those go under `## Open Questions & Disagreements`.
- Put a note's definition paragraph in a callout. The definition is plain prose right under the H1.
