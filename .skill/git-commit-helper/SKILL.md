---
name: git-commit-helper
description: Generate short Conventional Commits 1.0.0 messages automatically by reading the actual diff. Use this skill whenever the user runs or asks you to run `git commit`, stages changes, says "commit this", "write a commit message", "what should this commit say", "fix my commit message", "amend the message", or asks whether a change is a `feat` or a `fix`, needs a scope, or counts as a breaking change. Analyzes `git status` and `git diff` to pick the type, scope, and description, keeps the message to a single subject line unless the diff earns a body, splits unrelated changes into separate commits, and never pushes or rewrites published history without approval.
---

# Git Commit Helper

Turn a working tree into one or more **Conventional Commits 1.0.0** messages, derived from the
diff rather than from what the user said they were doing. The specification this skill implements
is compiled in [[concepts/version_control/conventional_commits|Conventional Commits]] — read that
note when a rule here is ambiguous; it is the authority on the format, and this skill is the
procedure for applying it.

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**The default output is one line.** Both optional parts stay empty unless the diff gives them
something to say. A commit message is an index entry for a change, not a summary of it — the diff
is already in the repository, and a reader who wants the detail reads that.

This skill operates under `AGENTS.md`, which always wins on conflict. Two of its prohibitions bind
every step below: **never `git push`, force-push, or rewrite published history** without explicit
user approval, and never bypass a hook with `--no-verify`.

## Core Rules

1. **Read the diff before naming the change.** The type, scope, and description are conclusions
   drawn from `git diff`, never from the user's one-line summary or the branch name. A message that
   contradicts its own diff is the one defect this skill exists to prevent.
2. **Only `feat` and `fix` carry SemVer meaning.** Every other type is convention and implies no
   release. Do not reach for `feat` to make a change sound significant, and do not file a
   behaviour-changing bug fix as `chore`.
3. **One commit, one type.** If the diff honestly fits two types, that is a signal to split it into
   two commits, not to pick the bigger one. See "Splitting a Working Tree" below.
4. **Describe the effect, not the edit.** `fix(parser): prevent racing of requests`, not
   `fix(parser): change the request handler`. A reader scanning `git log` wants to know what is
   different about the software now.
5. **Imperative mood, lowercase start, no trailing period.** `add`, not `added` or `adds`. The
   description completes the sentence "this commit will …".
6. **Aim for a 50-character subject line; 72 is the hard ceiling.** If the description will not
   fit, the commit is usually doing too much — split it before reaching for the body.
7. **A breaking change is signalled explicitly or not at all.** Use `!` before the colon, a
   `BREAKING CHANGE:` footer, or both. `BREAKING CHANGE` is the one token that **must** be
   uppercase. A break may ride on any type, including `refactor` and `chore`.
8. **A body is the exception, not the default.** Write one only when the diff raises a *why* the
   subject cannot carry — the motivation, the alternative rejected, the consequence for callers —
   and cap it at one paragraph of three or four lines. Never restate the file list, never narrate
   the diff hunk by hunk, and never pad a one-line change into a paragraph to look thorough.
9. **Match the repository's existing convention.** Read `git log` before writing. If the repo
   already uses a scope vocabulary or a type the table below omits, follow it; consistency inside
   one history beats a canonical list.
10. **Never stage or commit blind.** Show the user the proposed message and the files it covers
    before running `git commit`, and never `git add -A` without having read what is in the tree.
11. **Never commit secrets.** Scan the diff for keys, tokens, credentials, `.env` contents, and
    private URLs before staging. Stop and tell the user if you find one; do not quietly unstage it.

## Workflow: Generating a Commit

1. **Survey the tree.**

   ```sh
   git status --porcelain=v1
   git diff --stat            # unstaged
   git diff --staged --stat   # staged
   ```

   If something is already staged, that staged set **is** the commit the user intends — propose a
   message for it and leave the rest of the tree alone. If nothing is staged, go to step 5.

2. **Learn the local convention.**

   ```sh
   git log --oneline -20
   ```

   Note the scopes in use, whether bodies are customary, and whether the repo has a non-standard
   type. Also check for a `commitlint` config or a `.gitmessage` template.

3. **Read the actual changes**, not just the stat:

   ```sh
   git diff --staged     # or `git diff` for the unstaged tree
   ```

   For a large diff, read it file by file rather than skimming the summary. New files appear only
   under `git status`, so check untracked paths too.

4. **Classify.** Work out the single sentence that describes the change's effect, then pick the
   type from the table below, then the scope, then compress the sentence into the description.

5. **Stage, if needed.** With nothing staged, group the tree into logically coherent commits
   (step "Splitting a Working Tree") and stage only the first group:
   `git add <paths>`, or `git add -p` when one file holds two unrelated changes.

6. **Propose before committing.** Show the user the exact message and the file list it covers. Wait
   for approval.

7. **Commit.** Pipe the message in so multi-line bodies and footers survive shell quoting intact:

   ```sh
   git commit -F - <<'EOF'
   fix(parser): prevent racing of requests

   Introduce a request id and a reference to latest request. Dismiss
   incoming responses other than from latest request.

   Refs: #123
   EOF
   ```

   Never pass `--no-verify`. If a hook rejects the commit, fix the cause and report it.

8. **Verify and report.** `git log -1 --stat`, then tell the user what landed and what remains
   uncommitted. **Do not push** — `AGENTS.md` requires explicit approval for that.

## Choosing the Type

| Type       | Use when the diff…                                              | Release |
| ---------- | ---------------------------------------------------------------- | ------- |
| `feat`     | adds a capability a user or caller can now invoke                | MINOR   |
| `fix`      | corrects wrong behaviour that previously shipped                 | PATCH   |
| `docs`     | changes documentation, prose, or comments only                   | none    |
| `refactor` | restructures code with no behavioural change                     | none    |
| `perf`     | makes existing behaviour measurably faster or cheaper            | none    |
| `test`     | adds or corrects tests only                                      | none    |
| `build`    | changes the build system, packaging, or dependency pins          | none    |
| `ci`       | changes CI configuration, pipelines, or workflow files           | none    |
| `chore`    | is maintenance touching neither behaviour, docs, nor tests       | none    |
| `style`    | changes formatting or whitespace only                            | none    |
| `revert`   | undoes an earlier commit; name the SHAs in a `Refs:` footer      | none    |

Any of these becomes **MAJOR** when marked `!` or carrying a `BREAKING CHANGE:` footer.

### Tie-breakers

- **`feat` vs `fix`** — did the capability exist and misbehave (`fix`), or not exist (`feat`)?
- **`fix` vs `refactor`** — would a user notice the difference? If yes it is a `fix`, however small
  the edit.
- **`refactor` vs `perf`** — `perf` only when speed or cost was the *goal* and the diff shows it.
- **`chore` vs `build`** — dependency and packaging changes are `build`; `chore` is the residue
  that fits nowhere else, not a default.
- **`docs` vs `feat`** — documenting an existing feature is `docs`. Only shipping new capability is
  `feat`.
- **Formatting swept in alongside logic** — `style` describes a formatting-only commit. If
  formatting rode along with a real change, keep the real type and do not mention the reformatting.

## Choosing the Scope

The scope is an optional noun naming the part of the codebase the change touches:
`fix(parser):`. Use one when it tells the reader something the description does not — and omit it
rather than inventing a vague one.

- Prefer a scope the repo already uses; `git log` is the vocabulary.
- One word, lowercase, no path separators: `(api)`, not `(src/api/handlers)`.
- A change spanning several areas takes **no scope**, not a list of them.
- A scope that merely repeats a word already in the description earns nothing — drop it.

### Scopes in this vault

This repository is a markdown knowledge base, so the scope names the part of the vault, and `docs`
is the overwhelmingly common type — note content is the product here:

| Change                                     | Message shape                                 |
| ------------------------------------------ | --------------------------------------------- |
| New or expanded note under `wiki/concepts/`| `docs(<domain-folder>): …` — e.g. `docs(databases): add isolation levels note` |
| Rename, merge, or delete of a note         | `refactor(wiki): …` — structure changed, content did not |
| `wiki/INDEX.md` or `wiki/log.md` only      | `docs(index): …` / `docs(log): …`             |
| New or changed skill under `.skill/`       | `feat(skill): …` for a new skill, `docs(skill): …` for a wording change |
| `AGENTS.md` rule change                    | `docs(agents): …`, with `!` when it reverses an existing rule |
| Asset added under `wiki/assets/`           | `chore(assets): …`                            |

Per `AGENTS.md` §4, a note edit is only complete alongside its `INDEX.md` and `log.md` updates — so
those companion edits belong **in the same commit** as the note, not in a separate `docs(index):`
commit. Use the `index`/`log` scopes only when the audit files changed on their own.

## Breaking Changes

Signal a break whenever the diff removes or renames something callers depend on, changes a default,
tightens validation, or alters an output format. Prefer both signals for anything consequential:

```text
feat(api)!: drop support for Node 6

BREAKING CHANGE: uses JavaScript features not available in Node 6.
Callers on Node 6 must upgrade to Node 8 or later before updating.
```

The `!` makes the break visible in `git log --oneline`; the footer gives the migration path. The
footer token may also be written `BREAKING-CHANGE`. With `!` alone, the description itself must
describe the break — `feat!: rewrite config loader` tells a reader nothing about what broke.

## Body and Footers

- **Blank line before the body**, always. A body attached directly under the subject is parsed as
  part of the description by every tool that reads this format.
- The body explains **why**, and what a reader would otherwise have to reconstruct from the diff:
  motivation, the approach rejected, the follow-up now required. Wrap at ~72 columns, and stop at
  three or four lines. If it runs longer, the detail belongs in the note, the issue, or the pull
  request — not in `git log`.
- Before keeping a body, delete it and re-read the subject. If nothing important was lost, it was
  not a body; it was padding.
- **Blank line before the footer block.** Each footer is a token, a separator (`: ` or ` #`), and a
  value. The token uses `-` in place of spaces — `Reviewed-by`, `Co-authored-by`, `Acked-by` — which
  is exactly what lets a parser tell footers apart from a multi-paragraph body. `BREAKING CHANGE`
  is the sole exception, written with a space and in uppercase.
- Common footers: `Refs: #123`, `Closes #123`, `Reviewed-by: Z`, `Co-authored-by: Name <email>`.
- Only claim `Closes #123` when the user confirmed the issue number. Never guess one from a branch
  name.

## Splitting a Working Tree

An unstaged tree holding two unrelated changes gets two commits. Propose the split before staging:

1. Group the changed paths by the single sentence that describes each group's effect. Two sentences
   means two commits.
2. Order the groups so each commit leaves the tree working — dependency or scaffolding first,
   the feature that uses it second.
3. Stage group one with `git add <paths>`, or `git add -p` when one file contains both changes.
4. Commit, then repeat from step 1 of the main workflow for the remainder.

Signals that a tree needs splitting: a diff whose honest description needs the word "and"; a bug
fix sitting alongside a new feature; a repo-wide reformat mixed with a logic change; vendored or
generated files alongside hand-written ones.

Do **not** split a note and its required `INDEX.md`/`log.md` updates — that is one logical change
in this vault (see "Scopes in this vault").

## Fixing a Message

- **Not yet pushed, most recent commit** — `git commit --amend -F -` with the corrected message.
- **Not yet pushed, older commit** — `git rebase -i <base>`, mark the commit `reword`. Confirm with
  the user first; it rewrites local history.
- **Already pushed** — stop and ask. Rewriting published history is prohibited by `AGENTS.md`
  without explicit approval. A non-conforming commit already in the history is not a catastrophe:
  it simply becomes invisible to the tools that read the log.

## Worked Examples

Most commits look like the first two. The longer forms are the minority that earned the extra
lines.

```text
docs: correct spelling of CHANGELOG
```

```text
feat(lang): add Polish language
```

```text
docs(data-governance): add data sanity check note

Separates cheap pre-flight assertions from full validation, which the
quality note previously conflated. Two unresolved questions recorded
under Open Questions.
```

```text
fix: prevent racing of requests

Dismiss responses from anything but the latest request id. The timeouts
that previously mitigated this are now obsolete and were removed.

Reviewed-by: Z
Refs: #123
```

```text
revert: let us never again speak of the noodle incident

Refs: 676104e, a215868
```

## Definition of Done

- [ ] The message was derived from a diff that was actually read, and describes the change's effect rather than its edits.
- [ ] The subject line is `<type>[(scope)][!]: <description>` — colon, single space, lowercase imperative description, no trailing period, around 50 characters and never over 72.
- [ ] The message is a single line unless the diff raised a *why* the subject could not carry.
- [ ] The type is the single best fit from the table; a diff needing two types was split into two commits.
- [ ] The scope, if present, exists in the repo's vocabulary and adds information the description does not.
- [ ] Every breaking change carries `!`, a `BREAKING CHANGE:` footer, or both, with an uppercase token and a stated migration path.
- [ ] A body, if present, is separated by a blank line, explains *why*, and runs no more than three or four lines; footers are separated by a blank line and use hyphenated tokens.
- [ ] Issue numbers and co-authors were confirmed by the user, not inferred.
- [ ] The diff was scanned for secrets before staging.
- [ ] The user approved the message and the file list before `git commit` ran; no `--no-verify`, no push.
- [ ] In this vault, a note's `INDEX.md` and `log.md` updates landed in the same commit as the note.
