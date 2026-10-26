---
name: git-commit-helper
description: Generate short Conventional Commits 1.0.0 messages automatically by reading the actual diff. Use this skill whenever the user runs or asks you to run `git commit`, stages changes, says "commit this", "write a commit message", "what should this commit say", "fix my commit message", "amend the message", or asks whether a change is a `feat` or a `fix`, needs a scope, or counts as a breaking change. Analyzes `git status` and `git diff` to pick the type, scope, and description, keeps the message to a single subject line unless the diff earns a body, splits unrelated changes into separate commits, and never pushes or rewrites published history without approval.
---

# Git Commit Helper

Turn a working tree into one or more **Conventional Commits 1.0.0** messages, derived from the
diff rather than from what the user said they were doing. You already know the specification; this
skill is the procedure and this vault's conventions. When a format rule is genuinely ambiguous, the
compiled spec is [[concepts/version_control/conventional_commits|Conventional Commits]].

This skill operates under `AGENTS.md`, which wins on conflict: **never `git push`, force-push, or
rewrite published history** without explicit approval, and never bypass a hook with `--no-verify`.

## Rules

1. **The diff decides the message.** Type, scope, and description are conclusions drawn from the
   changes you read — never from the user's summary or the branch name. A message that contradicts
   its own diff is the defect this skill exists to prevent.
2. **One line by default.** A commit message is an index entry for a change, not a summary of it;
   the diff is already in the repository. Add a body only when the diff raises a *why* the subject
   cannot carry — motivation, a rejected alternative, a consequence for callers — and cap it at
   three or four lines. Never list files or narrate hunks.
3. **Describe the effect, not the edit.** `fix(parser): prevent racing of requests`, not
   `fix(parser): change the request handler`. Imperative, lowercase start, no trailing period,
   aim for 50 characters, 72 at most. If it will not fit, the commit is doing too much — split it.
4. **One commit, one type.** A diff that honestly needs two types, or a description that needs
   the word "and", is two commits.
5. **Only `feat` and `fix` imply a release.** Don't inflate a change to `feat`, and don't hide a
   behaviour-changing fix as `chore`.
6. **Signal breaks explicitly.** `!` before the colon and/or a `BREAKING CHANGE:` footer (the one
   token that must be uppercase) whenever something callers rely on is removed, renamed, or changes
   default or format. With `!` alone, the description itself must say what broke.
7. **Never commit secrets.** If the diff contains keys, tokens, credentials, or `.env` contents,
   stop and tell the user; don't quietly unstage.
8. **Never invent references.** `Closes #123` or a co-author only when the user supplied it.

## Workflow

**1. Survey — one command.**

```sh
git status --porcelain=v1 -uall && echo '--- staged' && git diff --staged --stat \
  && echo '--- unstaged' && git diff --stat && echo '--- log' && git log --oneline -15
```

The log shows the scope vocabulary in use. `-uall` lists every untracked file individually instead
of collapsing new directories.

**2. Read the changes, not the stat.**

- Something staged → that staged set **is** the intended commit. Read `git diff --staged` and leave
  the rest of the tree alone.
- Nothing staged → read `git diff` **and open every untracked (`??`) file**. `git diff` does not
  show new files, and in this vault new notes are the most common change, so skipping them means
  guessing.

Read independent files in parallel. For a large diff, read file by file rather than trusting the
stat.

**3. Classify and group.** Write the one sentence that describes each logical change's effect. One
sentence → one commit; several → a split (below). Then pick type, scope, and description.

**4. Confirm or proceed.**

- The user asked to commit and the tree is **one** clear commit → show the message and file list,
  then commit in the same turn. The request was the approval.
- A split, an uncertain classification, a found secret, or the user asked only for a *message* →
  propose and wait.

**5. Stage, commit, verify — one command.** Stage explicit paths (never `git add -A` blind); use
`git add -p` only when one file holds two unrelated changes. Pipe the message so bodies and
footers survive quoting:

```sh
git add wiki/concepts/databases/isolation_levels.md wiki/INDEX.md wiki/log.md \
  && git commit -F - <<'EOF'
docs(databases): add isolation levels note

Co-Authored-By: Name <email>
EOF
git log -1 --stat
```

Append any trailers the environment requires (e.g. a `Co-Authored-By` attribution line) as
footers, after a blank line. If a hook rejects the commit, fix the cause and report it. Finish by
telling the user what landed and what remains uncommitted. **Do not push.**

## Choosing the Type

`feat` new capability (MINOR) · `fix` corrects shipped behaviour (PATCH) · `docs` · `refactor` · `perf`
· `test` · `build` (build system, dependency pins) · `ci` · `style` (formatting only) · `chore`
(residue) · `revert` (`Refs:` footer with the SHAs). Any becomes MAJOR with `!` or `BREAKING CHANGE:`.

Tie-breakers — these are where mistakes happen:

- **`feat` vs `fix`** — did the capability exist and misbehave (`fix`), or not exist (`feat`)?
- **`fix` vs `refactor`** — would a user notice the difference? Then it is a `fix`, however small.
- **`refactor` vs `perf`** — `perf` only when speed or cost was the goal and the diff shows it.
- **`chore` vs `build`** — dependency and packaging changes are `build`; `chore` is not a default.
- **`docs` vs `feat`** — documenting existing behaviour is `docs`.
- **Formatting riding along with logic** — keep the real type; don't mention the reformat.

**Scope:** optional, one lowercase word, preferably one already in `git log`. Omit it when the
change spans several areas, or when it would only repeat a word in the description.

## This Vault's Conventions

Note content is the product here, so `docs` is the common type. These conventions supersede the
older history: commits before the skill existed used `feat:` and `feat(wiki):` for notes — don't
imitate them.

| Change                                      | Message shape                                                        |
| ------------------------------------------- | -------------------------------------------------------------------- |
| New or expanded note under `wiki/concepts/` | `docs(<domain-tag>): …` — kebab-case tag, e.g. `docs(ai-engineering): add RAG note` |
| Rename, merge, or delete of a note          | `refactor(wiki): …` — structure changed, content did not             |
| `wiki/INDEX.md` or `wiki/log.md` alone      | `docs(index): …` / `docs(log): …`                                    |
| Skill under `.skill/`                       | `feat(skill): …` new skill · `docs(skill): …` change · `docs(skill)!: …` retirement |
| `AGENTS.md`                                 | `docs(agents): …`, with `!` when it reverses an existing rule        |
| Asset under `raw/assets/`                   | `chore(assets): …`                                                   |
| `.gitignore`, README, CI                    | `chore: …` / `docs: …` / `ci: …`                                     |

**Never split a note from its `INDEX.md` and `log.md` updates.** `AGENTS.md` §1.4 makes them one
transaction, so they belong in the note's commit. Notes in different domains are separate commits
unless one request produced them together.

## Fixing a Message

- **Most recent commit, not pushed** — `git commit --amend -F -` with the corrected message.
- **Older commit, not pushed** — confirm first (it rewrites local history). Interactive rebase is
  unavailable here, so reword non-interactively:

  ```sh
  GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/edit/'" git rebase -i <sha>~1
  git commit --amend -F - <<'EOF'
  <corrected message>
  EOF
  GIT_EDITOR=: git rebase --continue
  ```

- **Already pushed** — stop and ask. A non-conforming commit in published history is harmless;
  rewriting it is prohibited without approval.

## Examples

```text
docs(data-governance): add data sanity check note
```

```text
docs(skill)!: retire obsidian-markdown skill
```

```text
fix: prevent racing of requests

Dismiss responses from anything but the latest request id. The timeouts
that previously mitigated this are now obsolete and were removed.

Refs: #123
```

## Done When

- [ ] The message came from a diff that was read in full, untracked files included.
- [ ] Subject is `<type>[(scope)][!]: <description>`, imperative, ≤72 characters, no period.
- [ ] One line, unless a body explains a *why* in at most four lines.
- [ ] One type per commit; unrelated changes were split; a note shipped with its `INDEX.md`/`log.md`.
- [ ] Breaks are signalled; references and co-authors were supplied, not inferred.
- [ ] No secrets staged, no `--no-verify`, no push.
