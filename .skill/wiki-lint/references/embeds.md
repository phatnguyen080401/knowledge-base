# Embeds Reference

The vault embeds **images and PDFs only**, stored in `raw/assets/` and named `snake_case` with the
related concept as a prefix (`AGENTS.md` §2). Note transclusion, audio, video, Bases, and search
embeds are banned ([obsidian-syntax.md](obsidian-syntax.md#banned-in-this-vault)).

## Images

```markdown
![[raw/assets/data_quality_dimensions.png]]
![[raw/assets/data_quality_dimensions.png|600]]        Width in px, keeps aspect ratio
![[raw/assets/data_quality_dimensions.png|600x400]]    Width x height
```

- Always write the full `raw/assets/…` path, so the link is unambiguous for agents and for GitHub
  readers.
- Prefer a width of 600 or less for diagrams, so they fit the reading pane.
- Follow the embed with one sentence saying what the image shows. That sentence is the image's alt
  text for every reader outside Obsidian.

## External Images

Allowed only when the user supplies the URL and the image cannot be saved to `raw/assets/`:

```markdown
![Six data quality dimensions](https://example.org/dimensions.png)
```

## PDFs

```markdown
![[raw/assets/dama_dmbok_ch11.pdf#page=3]]             Open at page 3
![[raw/assets/dama_dmbok_ch11.pdf#height=400]]         Viewer height in px
```

Embed a PDF only when a specific page carries a figure or table the note discusses. Cite the PDF in
`sources` as usual; the embed is not a citation.

## Adding an Asset

1. Move or save the binary to `raw/assets/<concept>_<what_it_shows>.<ext>`. Never overwrite an
   existing asset with the same name; pick a more specific name instead.
2. Embed it with the full path, then add the describing sentence.
3. Fold the asset into the note's `wiki/log.md` entry as one clause
   ([`wiki-audit-trail`](../../wiki-audit-trail/SKILL.md)).
