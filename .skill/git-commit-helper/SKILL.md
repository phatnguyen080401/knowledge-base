---
name: git-commit-helper
description: Write a Conventional Commits message from the actual diff, then commit. Use whenever the user runs or asks you to run `git commit`, stages changes, says "commit this", "write a commit message", "what should this commit say", "fix my commit message", or "amend the message", or asks whether a change is a `feat` or a `fix`, needs a scope, or is a breaking change.
---

# Git Commit Helper

Turn a working tree into one or more **Conventional Commits 1.0.0** messages, derived from the
diff rather than from what the user said they were doing. You already know the specification;
when a format rule is genuinely ambiguous, the compiled spec is
[[concepts/version_control/conventional_commits|Conventional Commits]]. Never bypass a hook with
`--no-verify`.

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
sentence → one commit; several → a split. Then pick type, scope, and description.

**4. Confirm or proceed.**

- The user asked to commit and the tree is **one** clear commit → show the message and file list,
  then commit in the same turn. The request was the approval.
- A split, an uncertain classification, a found secret, or the user asked only for a *message* →
  propose and wait.
- Amending or rewording an existing commit → read
  [fixing-a-message.md](references/fixing-a-message.md) first.

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

Types: `feat` (MINOR), `fix` (PATCH), `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `style`,
`chore`, `revert` (with a `Refs:` footer naming the SHAs). Any becomes MAJOR with `!` or
`BREAKING CHANGE:`.

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

Note content is the product here, so `docs` is the common type. Commits from before this skill used
`feat:` and `feat(wiki):` for notes — don't imitate them.

| Change | Message shape |
| --- | --- |
| New or expanded note under `wiki/concepts/` | `docs(<domain-tag>): …` — kebab-case tag, e.g. `docs(ai-engineering): add RAG note` |
| Rename, merge, or delete of a note | `refactor(wiki): …` — structure changed, content did not |
| `wiki/INDEX.md` or `wiki/log.md` alone (with `wiki/hot.md` for a query) | `docs(index): …` / `docs(log): …` |
| Skill under `.skill/` | `feat(skill): …` new skill · `docs(skill): …` change · `docs(skill)!: …` retirement |
| `AGENTS.md` | `docs(agents): …`, with `!` when it reverses an existing rule |
| Asset under `raw/assets/` | `chore(assets): …` |
| `.gitignore`, README, CI | `chore: …` / `docs: …` / `ci: …` |

**Never split a note from its `INDEX.md` and `log.md` updates.** `AGENTS.md` §1.4 makes them one
transaction, so they belong in the note's commit. Notes in different domains are separate commits
unless one request produced them together.

## Example

```text
fix: prevent racing of requests

Dismiss responses from anything but the latest request id. The timeouts
that previously mitigated this are now obsolete and were removed.

Refs: #123
```

## Done When

- [ ] The message came from the diff read in full, untracked files included; the subject is `<type>[(scope)][!]: <description>`, imperative, ≤72 characters, no period, with a body only for a *why*.
- [ ] One type per commit; unrelated changes were split; a note shipped with its `INDEX.md`/`log.md`; breaks are signalled; references and co-authors were supplied, not inferred.
- [ ] No secrets staged, no `--no-verify`, no push.
