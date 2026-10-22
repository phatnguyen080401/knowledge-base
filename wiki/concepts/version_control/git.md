---
title: Git
tags: [version-control, source-history, git, overview]
created: 2026-10-22 10:11:51
updated: 2026-10-22 10:43:17
---

# Git

Git is a distributed version-control system that records a project's history as a directed acyclic graph of immutable, content-addressed snapshots. Every clone holds the complete history and can commit, branch, and merge without a server, which is what separates Git from the centralized systems it displaced. This note is the hub for the version-control domain: it covers the object model first and the command surface second, because almost every confusing Git command becomes obvious once you know which of the four areas it moves data between. Message conventions layered on top live in [[concepts/version_control/conventional_commits|Conventional Commits]].

## Why the Model Comes First

Git's commands are notoriously hard to memorize and easy to derive. `reset`, `revert`, `restore`, and `checkout` all sound like "undo" and do four different things; `pull` is two commands wearing a coat. The reason the surface looks arbitrary is that it grew around a very small, very regular core — four object types and a set of movable pointers. Learn the core and the commands stop being a list to memorize and become a short set of verbs applied to known nouns.

Two properties of the core do most of the explanatory work:

- **Objects are immutable and addressed by the hash of their content.** Nothing is ever edited in place. "Changing" a commit means creating a new one with a new hash, which is why every history-rewriting command produces new commit IDs and why rewriting shared history is disruptive.
- **Branches are not containers, they are pointers.** A branch is a 41-byte file holding a commit hash. Creating one is free, deleting one throws away no data, and "moving a commit between branches" is nearly always just moving a pointer.

## The Object Model

Git stores four kinds of object, each keyed by the hash of its own contents (historically SHA-1; a SHA-256 object format exists but is not the default and is not interoperable with SHA-1 repositories).

| Object     | Holds                                                                     | Analogy             |
| ---------- | ------------------------------------------------------------------------- | ------------------- |
| **blob**   | The bytes of one file version. No filename, no permissions, no history    | File contents       |
| **tree**   | A directory listing: names, modes, and the blob or tree hash of each entry | Directory           |
| **commit** | One root tree, zero or more parents, author and committer with timestamps, and the message | Snapshot + metadata |
| **tag**    | A named pointer to another object, with its own message and optional signature | Annotated label     |

A commit therefore points at a *complete snapshot of the whole tree*, not at a diff. Diffs are computed on demand by comparing two trees — which is why `git log -p` is slower than `git log`, and why storing the same unchanged file across a thousand commits costs one blob, since identical content hashes to the same object.

**References** are the mutable layer on top. A branch, a remote-tracking branch (`origin/main`), and a lightweight tag are all just files under `.git/refs/` containing a commit hash. `HEAD` is a pointer to the branch you are currently on — or, in **detached HEAD** state, directly to a commit, which is why commits made there belong to no branch and become unreachable once you switch away.

```text
blob ──┐
blob ──┼──► tree ──► commit ──► commit ──► commit ◄── main (branch ref)
tree ──┘                                      ▲
                                             HEAD
```

**Porcelain vs. plumbing.** The commands below are *porcelain* — the human-facing layer. Underneath sits *plumbing*: `git hash-object`, `git cat-file -p <hash>`, `git ls-tree`, `git rev-parse`. You rarely need plumbing, but `git cat-file -p HEAD` printing a commit's raw tree, parent, and author lines is the fastest way to convince yourself the model above is literally what is on disk.

## The Four Areas

Nearly every everyday command moves content between four places. Knowing which pair a command connects is usually enough to predict what it does.

| Area                    | What it is                                                     | Moved by                                       |
| ----------------------- | --------------------------------------------------------------- | ---------------------------------------------- |
| **Working tree**        | The files you actually edit                                     | Your editor                                    |
| **Index** (staging area) | A binary file listing exactly what the next commit will contain | `git add`, `git restore --staged`              |
| **Local repository**    | The object database and refs in `.git/`                         | `git commit`, `git merge`, `git rebase`        |
| **Remote repository**   | Another copy of the object database, usually on a server        | `git push`, `git fetch`                        |

The index is the part other version-control systems do not have, and the part people fight with. It exists so that a commit is something you *compose* rather than something that happens to whatever files you last touched — `git add -p` to stage one hunk of a file and leave the rest is the feature that justifies the whole concept.

## Setup

```bash
git config --global user.name  "Ada Lovelace"      # identity recorded in every commit
git config --global user.email "ada@example.com"
git config --global init.defaultBranch main        # new repos start on main, not master
git config --global pull.rebase true               # see "Working with Remotes"
git config --list --show-origin                    # which file set which value

git init                    # create a repository in the current directory
git clone <url> [<dir>]     # copy an existing one, including all history
```

Configuration resolves system → global (`~/.gitconfig`) → repository (`.git/config`) → command line, each overriding the last. A per-repository `user.email` is the usual fix for committing to work and personal repositories from one machine.

## Recording Changes

```bash
git status                   # what is modified, staged, and untracked
git status -sb               # the same, two lines shorter

git add <path>               # stage a file or directory
git add -p                   # stage selected hunks interactively
git add -A                   # stage everything, including deletions

git diff                     # working tree vs. index  — what is NOT staged
git diff --staged            # index vs. HEAD          — what IS staged
git diff HEAD                # working tree vs. HEAD   — everything uncommitted

git commit -m "<message>"    # commit the index
git commit -am "<message>"   # stage tracked modifications and commit (skips untracked files)

git rm <path>                # delete and stage the deletion
git rm --cached <path>       # stop tracking but keep the file on disk
git mv <old> <new>           # rename; Git detects renames by content anyway
```

The two `git diff` forms are worth internalizing: a bare `git diff` showing nothing while `git status` shows staged changes is not a bug, it is the index doing its job.

**`.gitignore`** excludes untracked files by glob, with per-directory files and a global one via `core.excludesFile`. It has no effect on a file already tracked — that requires `git rm --cached` first. Commit message conventions are a topic of their own: see [[concepts/version_control/conventional_commits|Conventional Commits]].

## Inspecting History

```bash
git log --oneline --graph --decorate --all   # the one log invocation worth aliasing
git log -p <path>                            # patches touching a path
git log -S "<string>"                        # commits that added or removed a string ("pickaxe")
git log --since="2 weeks ago" --author=ada
git show <commit>                            # one commit's metadata and diff
git blame <file>                             # last commit to touch each line
git shortlog -sn                             # commit counts per author
git bisect start / bad / good                # binary search for the commit that broke something
```

`git log -S` and `git bisect` are the two that repay learning out of proportion to their difficulty. Bisect in particular turns "when did this break?" from archaeology into $\log_2 n$ builds, and `git bisect run <script>` automates even that.

**`git reflog`** is the separate, local-only record of everywhere `HEAD` has pointed, including positions abandoned by `reset`, `rebase`, and branch deletion. It is the reason almost nothing committed is ever truly lost — see Undoing Things. Entries expire eventually (90 days by default, 30 for unreachable ones), so it is a safety net, not an archive.

## Branching and Merging

```bash
git branch                       # list local branches
git switch <branch>              # move HEAD to an existing branch
git switch -c <branch>           # create and move to a new one
git branch -d <branch>           # delete a merged branch (-D to force)
git merge <branch>               # merge into the current branch
git merge --no-ff <branch>       # force a merge commit even when fast-forward is possible
git merge --abort                # back out of a conflicted merge
```

`git switch` and `git restore` were added in Git 2.23 to split `git checkout`, which had accumulated two unrelated jobs — moving `HEAD` and overwriting files. `git checkout` still works and is what older documentation shows; the newer pair is clearer and much harder to use destructively by accident.

A merge takes one of two shapes:

- **Fast-forward** — the target branch is a direct ancestor of the source, so Git just advances the pointer. No merge commit, perfectly linear history, no record that a branch existed.
- **Three-way** — the branches diverged, so Git finds their **merge base** (the nearest common ancestor), combines both sets of changes relative to it, and records a commit with two parents.

A **conflict** occurs only when both sides changed the same region relative to the merge base. Git marks the region in the working tree, lists the files as unmerged in `git status`, and waits; you edit, `git add` the resolution, and `git commit`. `git merge --abort` returns to the pre-merge state at any point before that.

The merge-versus-rebase argument is really an argument about whether history should record *what happened* (merges, true but noisy) or *what you wish had happened* (rebase, readable but fictional). Both are defensible; mixing them unpredictably within one team is not.

## Rebasing and Rewriting History

```bash
git rebase <base>               # replay the current branch's commits on top of <base>
git rebase -i <base>            # interactively reorder, squash, edit, or drop them
git rebase --continue|--abort   # after resolving a conflict, or to give up
git commit --amend              # replace the most recent commit
git cherry-pick <commit>        # replay one commit onto the current branch
git revert <commit>             # a NEW commit that undoes an old one
```

Rebase does not move commits. It **creates new ones** with the same changes, new parents, new timestamps, and therefore new hashes, then moves the branch pointer to the end of the new chain. The originals linger, unreferenced, until garbage collection.

That mechanic produces the one rule worth stating absolutely:

> [!warning] The golden rule of rebasing
> Never rewrite commits that others have already pulled. Everyone who has the old commits now has a divergent history, and their next `git pull` will either merge the duplicates back in or demand a manual recovery. Rewrite freely on a local or personal branch; treat a shared branch as append-only.

`git revert` is the shared-history-safe counterpart: it adds an inverse commit rather than erasing anything, so the undo is itself a recorded, pushable fact.

Interactive rebase is the main tool for tidying a branch before review: `squash` and `fixup` collapse "fix typo" commits into their parent, `reword` corrects a message, `drop` removes a commit, and reordering is just reordering the lines.

## Undoing Things

The single most common Git question is "how do I undo this", and it has at least six answers depending on *what* and *how far along*.

| Goal                                              | Command                                   | Touches                        |
| ------------------------------------------------- | ----------------------------------------- | ------------------------------ |
| Discard edits to a file                           | `git restore <path>`                      | Working tree                   |
| Unstage a file, keep the edits                    | `git restore --staged <path>`             | Index                          |
| Fix the last commit's message or contents         | `git commit --amend`                      | Last commit (new hash)         |
| Undo the last commit, keep changes staged         | `git reset --soft HEAD~1`                 | HEAD                           |
| Undo the last commit, keep changes unstaged       | `git reset HEAD~1` (`--mixed`, default)   | HEAD + index                   |
| Undo the last commit and destroy the changes      | `git reset --hard HEAD~1`                 | HEAD + index + working tree    |
| Undo a commit that is already pushed              | `git revert <commit>`                     | Adds a new commit              |
| Delete untracked files                            | `git clean -fd` (`-n` to preview first)   | Working tree                   |
| Recover from a bad reset or rebase                | `git reflog` then `git reset --hard <ref>` | HEAD + index + working tree   |

The three `reset` modes are one command with a single parameter — how far down the stack to go — and that is the clearest way to remember them: `--soft` moves `HEAD` only, `--mixed` also resets the index, `--hard` also overwrites the working tree.

`--hard` and `git clean` are the only entries in the table that can destroy work irrecoverably, because uncommitted changes exist in no object. Anything that was ever committed is still reachable through `git reflog` until it expires.

**Stashing** parks uncommitted work without committing it:

```bash
git stash push -m "<label>"   # shelve working tree and index changes
git stash push -u             # include untracked files
git stash list
git stash pop                 # reapply the most recent and drop it
git stash apply stash@{2}     # reapply a specific one, keeping it in the list
```

A stash is implemented as a commit on a hidden ref, which is why a dropped stash can sometimes be recovered — but a stash is a worse branch, not a better one. Anything you want to keep for more than an afternoon should be a commit on a throwaway branch.

## Working with Remotes

```bash
git remote -v                       # configured remotes
git remote add <name> <url>
git fetch <remote> [--prune]        # download objects, update origin/*, touch nothing local
git pull                            # fetch + integrate into the current branch
git pull --rebase                   # fetch + rebase instead of merge
git push <remote> <branch>
git push -u origin <branch>         # push and set the upstream tracking branch
git push --force-with-lease         # overwrite a remote branch, but only if it is where you last saw it
```

**`fetch` is always safe; `pull` is not.** `fetch` only adds objects and moves remote-tracking refs, so nothing local can break. `pull` runs `fetch` and then merges or rebases, which can conflict or rewrite. Fetching first and looking at `git log HEAD..origin/main` before integrating is a cheap habit.

A **remote-tracking branch** (`origin/main`) is the local cache of where that branch stood at the last fetch. It is never updated by anyone else's pushes until you fetch again, which is why `git status` reporting "up to date" only means "up to date with what I last downloaded".

`--force-with-lease` is the safe form of `--force`: it refuses the push if the remote branch has moved since your last fetch, so you cannot silently discard a colleague's commits that you never saw. There is rarely a good reason to prefer plain `--force`.

## Tags and Releases

```bash
git tag                             # list
git tag -a v1.4.0 -m "Release 1.4.0"  # annotated: its own object, author, date, message
git tag v1.4.0                      # lightweight: just a ref, no metadata
git tag -s v1.4.0 -m "..."          # annotated and GPG-signed
git push origin v1.4.0              # tags are NOT pushed by default
git push --follow-tags              # push commits plus the annotated tags reachable from them
git describe --tags                 # human-readable name for the current commit: v1.4.0-12-gabc1234
```

Use annotated tags for anything a human or a pipeline will rely on — a lightweight tag carries no record of who created it or when. Tags are the natural trigger for a release pipeline and the natural place for a [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] number, which is what links Git's history to the artifact numbering downstream consumers depend on.

## Working with Large or Long-Lived Repositories

| Need                                                 | Command                                            |
| ---------------------------------------------------- | -------------------------------------------------- |
| Several branches checked out at once, no re-cloning  | `git worktree add ../feature-x feature-x`           |
| Clone without full history                           | `git clone --depth 1 <url>`                         |
| Clone without file contents until needed             | `git clone --filter=blob:none <url>` (partial clone)|
| Check out part of a large tree                       | `git sparse-checkout set <dir>...`                  |
| Keep a big repository fast                           | `git maintenance start`, `git gc`                   |
| Embed another repository at a pinned commit          | `git submodule add <url> <path>`                    |

`git worktree` is the underused one: it gives a second working directory sharing the same object database, which beats stashing when you need to look at another branch for five minutes. Submodules, by contrast, are correct but awkward enough that most teams reach for a package manager instead.

## Pitfalls

- **Committing secrets.** Deleting the file in a later commit removes nothing — the blob is still in history and still reachable. The only real fixes are rewriting history across every clone and, non-negotiably, rotating the credential. Prevention (an ignore rule, a pre-commit secret scan) is far cheaper than the cure.
- **Rebasing a shared branch.** See the golden rule above. The symptom is a colleague reporting duplicated commits after a pull.
- **`git reset --hard` with uncommitted work.** The reflog cannot save what was never committed. Stash or commit first; `--hard` is not an undo.
- **Confusing `revert` with `reset`.** `revert` is forward-moving and safe to push; `reset` rewrites and is not.
- **Trusting `origin/main` without fetching.** It is a cache, not a live view.
- **Large binaries.** Every version of every binary lives in the history of every clone forever. Git LFS or an artifact store, not the repository.
- **Long-lived feature branches.** Merge pain grows with divergence, not with diff size. Integrate often.

## Related Concepts

- [[concepts/version_control/conventional_commits|Conventional Commits]] — the structured message format that turns the history this note describes into something tooling can read
- [[concepts/version_control/gitlab/gitlab_repository_security|GitLab Repository Security]] — the server-side enforcement Git itself has no notion of: who may force push, who may delete a tag, and what a push rule rejects before it is stored
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — what an annotated release tag usually carries, and the scheme commit types map onto
- [[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]] — a worked pipeline triggered by pushes and tags, and the state-deferral pattern that depends on branch comparison
- [[concepts/devops/trivy|Trivy]] — the repository and filesystem scanning that a pre-commit hook or CI job runs against the tree Git is tracking

## References

- [Pro Git](https://git-scm.com/book/en/v2) — Chacon & Straub; the canonical book, free online
- [Git reference manual](https://git-scm.com/docs) — per-command documentation, including the plumbing commands
- [`git switch`/`git restore` announcement](https://github.blog/open-source/git/highlights-from-git-2-23/) — why `git checkout` was split
