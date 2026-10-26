---
title: GitLab Repository Security
tags: [version-control, source-history, supply-chain-security, access-control, ci-cd, gitlab, how-to, needs-review]
sources: ["https://best.openssf.org/SCM-BestPractices/gitlab/", "https://docs.gitlab.com/user/project/repository/branches/protected/", "https://docs.gitlab.com/user/project/repository/push_rules/"]
created: 2026-10-22 10:43:17
updated: 2026-10-26 18:29:25
---

# GitLab Repository Security

The settings a GitLab project exposes to stop damaging changes reaching its default branch, to stop secrets and oversized files entering its history, and to limit what a pipeline can reach once it runs. [[concepts/version_control/git|Git]] itself enforces almost none of this — it is a content-addressed object store with no notion of permission — so every control below is a *server-side* policy GitLab applies at push time, at merge time, or at job time. This note is the hardening checklist for a project, organized by the settings screen each control lives on.

## Why It Matters

Git's own model is the reason a forge needs these controls. Every clone is a complete copy of the history, commits are immutable but branch pointers are not, and the identity on a commit is a self-declared string in a plain-text header. The three failure modes that follow are the ones the settings below exist to close:

- **History is destroyable from a client.** A force push replaces a branch pointer; the old commits become unreachable and are garbage-collected. Nothing in Git objects to this, and the only durable record of what the branch used to hold is the forge's own reflog.
- **Anything committed is permanent and distributed.** Deleting a leaked key in a later commit removes nothing — the blob is still in history, still in every clone, and still in every fork. Rewriting it out is an incident, not a fix.
- **Authorship is a claim, not a proof.** `user.email` is whatever the committer set it to, so a commit can carry a colleague's name unless signatures or a server-side author check are enforced.

Each control has a cost — usually a slower merge or a role someone no longer has — so the shape of a sensible configuration is: lock the default branch and the release tags hard, make everything else cheap to work with.

## Roles and What They Unlock

GitLab's permissions are role-based, and most protection settings are expressed as "which role, or which named user, may do this". The five project roles, in increasing order:

| Role           | Can, roughly                                                              |
| -------------- | ------------------------------------------------------------------------- |
| **Guest**      | View issues and (for public projects) the repository                       |
| **Reporter**   | Read the code, view pipelines and reports                                  |
| **Developer**  | Push to unprotected branches, open merge requests, run pipelines           |
| **Maintainer** | Configure protection rules, push to protected branches, manage CI variables and members |
| **Owner**      | Everything, including deleting or transferring the project                 |

> [!tip] The protection boundary is Developer vs. Maintainer
> Nearly every control in this note is really the sentence "Developers may propose, Maintainers may configure." If a change can be made by whoever makes the change, it is not a control. Keep the Maintainer set small, and keep Owner smaller.

## Protected Branches

**Settings → Repository → Protected branches** (consolidated into **Branch rules** in recent versions). The default branch is protected on creation.

| Action                     | Who can do it                                                       |
| -------------------------- | -------------------------------------------------------------------- |
| Protect a branch           | Maintainer or above                                                  |
| Push to the branch         | Only the roles, users, or groups in **Allowed to push and merge**    |
| Merge into the branch      | Only the roles, users, or groups in **Allowed to merge**             |
| Force push to the branch   | No one, unless **Allow force push** is deliberately turned on         |
| Delete the branch          | No one                                                               |

The hardened setting is **Allowed to push and merge: No one**, **Allowed to merge: Developers and Maintainers**, force push off. That makes the merge request the only way code reaches the branch, including for Maintainers — which is the point, since a rule that administrators route around is a rule that records nothing.

Patterns are supported, so `release/*` or `v*` can be protected in one rule rather than per branch. Protecting a branch also stops its history being rewritten, which is the server-side enforcement of [[concepts/version_control/git|Git]]'s golden rule of rebasing: rewrite freely on your own branch, treat a shared one as append-only.

**Protected tags** sit on the same screen and are the forgotten half. A release tag that any Developer can delete and recreate against a different commit means the artifact a [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] number refers to is not fixed. Protect the release tag pattern and restrict creation to the role or pipeline that publishes releases.

## Branch Rules

**Settings → Repository → Branch rules** gathers per-branch policy in one place: who may push and merge, how many approvals a merge request into this branch needs, whether [Code Owners](https://docs.gitlab.com/user/project/codeowners/) must approve, and which external status checks must pass.

- **Required approvals.** At least one approval from someone other than the author is the minimum that makes review a fact rather than a habit. Two is the usual bar for a default branch.
- **Code Owners.** A `CODEOWNERS` file maps path globs to users or groups, so a change under `terraform/` requires the platform team and a change under `models/` requires the data team, without a human remembering to add them. Pair it with *required* Code Owner approval, or it is only a suggestion of reviewers.
- **Approval hygiene.** The rules worth enabling, all found under merge request approval settings: *prevent approval by the author*, *prevent approvals by users who add commits*, *prevent editing approval rules within a merge request*, and *require new approvals when new commits are pushed*. Without the last one, a branch can be approved and then changed.

## Push Rules

**Settings → Repository → Push rules** are evaluated server-side on every push and reject the whole push if any commit in it fails. They are the only controls here that act *before* anything is stored.

| Rule                                      | Catches                                                                   |
| ----------------------------------------- | -------------------------------------------------------------------------- |
| Reject unsigned commits                   | Commits with no GPG/SSH signature, i.e. unverifiable authorship            |
| Check whether the commit author is a GitLab user | A commit whose author email belongs to no account on the instance    |
| Commit author's email must match a regex  | Personal addresses pushed to a work repository                             |
| Prevent pushing secret files              | Files *named* like credentials — `id_rsa`, `*.pem`, `*.key`, shell history |
| Prohibited file names (regex)             | Anything else you never want tracked                                       |
| Required / forbidden commit message regex | Message format, issue references — e.g. enforcing [[concepts/version_control/conventional_commits\|Conventional Commits]] |
| Branch name regex                         | Ad-hoc branch names that break automation                                  |
| Maximum file size                         | Binaries that will live in every clone forever                             |

> [!warning] "Prevent pushing secret files" matches filenames, not contents
> It will stop `id_rsa`, and it will happily accept an AWS key pasted into `config.py`. Content-based blocking is the separate **secret push protection** feature (paid tiers), which scans the pushed diff for known token patterns and rejects the push. Treat the filename rule as a seatbelt, not the scanner, and run a client-side pre-commit secret scan as well — the cheapest place to catch a secret is before the commit exists.

Signed commits deserve their own line. GitLab verifies GPG, SSH, and X.509 signatures and shows a **Verified** badge; the *reject unsigned commits* push rule is what turns that badge from decoration into a gate. Note that it also blocks commits created by some automation unless that automation signs too.

## Merge Request Controls

**Settings → Merge requests**.

- **Merge method** determines the history shape, and so determines what `git log` on the default branch is worth reading. *Merge commit* records every branch; *merge commit with semi-linear history* requires the source branch to be rebased first, so every merge is a clean one; *fast-forward merge* forbids merge commits entirely and gives a linear history with no record a branch existed.
- **Squash commits when merging** — *do not allow*, *allow*, *encourage*, or *require*. Requiring squash plus fast-forward merge gives one commit per merge request, which makes `git revert` on the default branch trivial, at the cost of losing the intermediate commits.
- **Merge checks** — *pipelines must succeed*, *all threads must be resolved*, and whether *skipped pipelines count as successful* (they do by default, which is a quiet hole if a `rules:` change can skip the security job).
- **Templates** live in `.gitlab/merge_request_templates/*.md` in the repository, so they are themselves reviewed and versioned. A useful template carries the change summary, the linked issue, a rollback note, and a short checklist — security impact, migrations, secrets touched. Issue templates work the same way from `.gitlab/issue_templates/`.

Keeping the template in the repository rather than in project settings matters: it means the review checklist evolves through the same merge-request process as the code it governs.

## CI/CD Hardening

**Settings → CI/CD**. The pipeline is the most privileged thing in the project — it holds the deploy credentials — so it is the highest-value target in it.

- **Turn off public pipelines.** For public projects this exposes job logs and artifacts to non-members; a log line is a very common way for a variable to escape.
- **Protect your variables.** A **protected** variable is exposed only to pipelines running on protected branches and tags, which is what stops a fork or a throwaway branch from printing the production key. A **masked** variable is redacted in job logs (masking requires the value to meet length and character constraints — silently unmasked otherwise). Use an **environment scope** so a staging job cannot see a production value.
- **Separate caches for protected branches.** Without this, a job on an unprotected branch can poison a cache that a protected-branch job later restores — a straightforward way to get code executed in a privileged context.
- **Set a pipeline timeout.** The default is generous; a tight timeout bounds both runaway spend and a hung job holding a runner.
- **Restrict the job token.** `CI_JOB_TOKEN` can authenticate to other projects; the job token allowlist limits which projects may use a token from this one, closing lateral movement between projects.
- **Protected environments.** Restrict who may deploy to each environment and require a deployment approval. This is the control that keeps "can merge" and "can release to production" as two different permissions.
- **Secure files** store keystores, provisioning profiles, and signing certificates outside the repository and outside the variable list, fetched by the job that needs them.
- **Mind the runner.** Shared runners execute untrusted code from forks; a project with production credentials wants protected runners that only pick up jobs from protected branches.

## Security Scanning

**Secure → Security configuration** enables the scanners as pipeline jobs; results surface on the merge request and in the vulnerability report.

| Scanner                   | Looks at                                                      |
| ------------------------- | --------------------------------------------------------------- |
| **SAST**                  | First-party source code, for injection, unsafe APIs, weak crypto |
| **Secret detection**      | Commit contents and history, for token and key patterns         |
| **Dependency scanning**   | Declared dependencies and lockfiles, against advisory databases |
| **Container scanning**    | OS and language packages inside a built image                   |
| **IaC scanning**          | Terraform, Kubernetes, and CloudFormation definitions           |
| **DAST**                  | The running application over HTTP                               |

Two points matter more than the list. First, a scanner that only *reports* changes nothing: the control is a **merge request approval policy** that requires a security approval when a new high-severity finding appears, or a job that fails the pipeline on a threshold. Second, a day-one gate on zero findings always fails — every mature repository starts with a backlog — so gate on *newly introduced* findings and burn the backlog down separately. The same reasoning applies to any scanner run in CI, including [[concepts/devops/trivy|Trivy]] as an alternative or a supplement.

**Secret push protection** belongs here too, but it is the only one that acts before the push lands rather than after. Every other scanner above tells you a secret is already in the history.

## When a Secret Does Leak

Prevention fails eventually, and the response order is not the intuitive one.

1. **Rotate the credential first.** Before any cleanup, before any investigation. Everything else is slower than an attacker with a valid key.
2. **Assume it is public.** It is in every clone, every fork, every CI cache, and possibly in a job log and a merge request diff — all of which survive a repository rewrite.
3. **Then purge the history.** **Settings → Repository → Repository cleanup** rewrites the repository from an object map produced by a history-rewriting tool. This changes every affected commit hash, so it is coordinated work: everyone re-clones, open merge requests are rebuilt.
4. **Find out how.** Audit events (paid tiers) show who pushed what and when, which is also how you tell a mistake from a compromised account.
5. **Close the path.** Add the pattern to the push rules, enable secret push protection, add a pre-commit scan. A cleanup without a new control is a scheduled repeat.

## Pitfalls

- **Protecting the branch but not the tags.** The default branch is immutable and the `v1.4.0` tag can be moved by anyone — so the release is not pinned.
- **Relying on `prevent pushing secret files` as a secret scanner.** It checks filenames. See the warning above.
- **Maintainers who can push directly.** Every exception to the review rule is a path with no record, and it will be used under deadline pressure.
- **Unprotected CI variables.** A production credential readable from any branch is readable from a fork's merge request pipeline.
- **Approvals that survive new commits.** Without *require new approvals when commits are added*, approval attaches to a branch, not to a diff.
- **Skipped pipelines counted as successful.** A `rules:` change that skips the pipeline then satisfies the "pipelines must succeed" check.
- **Settings that live only in the UI.** Protection configured per project drifts across dozens of projects; group-level settings, compliance frameworks, and security policies applied centrally are what make a rule hold at scale.

## Open Questions & Disagreements

- **Tier availability is version-dependent and not recorded here.** Push rules, Code Owners, protected environments, audit events, security policies, and secret push protection are paid-tier features, but which feature sits in which tier has moved between GitLab releases, and some scanners that began as Ultimate-only were later made broadly available. The claims above say "paid tiers" rather than naming Premium or Ultimate for this reason. Verify against the current GitLab documentation for the version actually deployed before planning around any single feature.
- **Self-managed vs. GitLab.com.** Several controls (instance-wide default branch protection, audit event retention, runner isolation) behave differently on a self-managed instance than on GitLab.com. The source material for this note did not distinguish the two.
- **Signed-commit enforcement vs. automation.** Requiring signed commits blocks bots and web-IDE edits that do not sign. Whether to carve out an exception, or to give the automation its own signing key, is unresolved and depends on how much of the history is machine-authored.

## Related Concepts

- [[concepts/version_control/git|Git]] — the object and ref model these settings constrain; force push, history rewriting, and tag mutability are Git behaviours GitLab is policing
- [[concepts/version_control/conventional_commits|Conventional Commits]] — the message format a commit-message push rule is most often used to enforce
- [[concepts/devops/trivy|Trivy]] — the same scanning categories as the Secure screen, as a vendor-neutral CI job rather than a built-in one
- [[concepts/data_governance/data_security|Data Security]] — the access-control and classification discipline these repository controls are one instance of
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — what a protected release tag is protecting the meaning of

## References

- [GitLab configuration best practices](https://best.openssf.org/SCM-BestPractices/gitlab/) — OpenSSF's hardening guide, the source of this note's structure
- [Protected branches](https://docs.gitlab.com/user/project/repository/branches/protected/) and [Push rules](https://docs.gitlab.com/user/project/repository/push_rules/) — GitLab documentation
- [Merge request approvals](https://docs.gitlab.com/user/project/merge_requests/approvals/) — approval rules and the hygiene settings
- [CI/CD variables](https://docs.gitlab.com/ci/variables/) — protected, masked, and environment-scoped variables
