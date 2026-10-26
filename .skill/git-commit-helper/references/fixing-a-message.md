# Fixing a Commit Message

Read this when the user asks to fix, amend, or reword an existing commit message.

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
  rewriting it is prohibited without approval (`AGENTS.md` §1).
