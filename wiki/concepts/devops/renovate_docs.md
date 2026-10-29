---
title: Renovate
tags: [devops, supply-chain-security, versioning, ci-cd, renovate, overview]
sources: [raw/processed/renovate_docs.md, "https://docs.renovatebot.com/"]
created: 2026-10-29 18:29:30
updated: 2026-10-29 18:29:30
---

# Renovate

Renovate is an open-source bot (AGPL-3.0-only) that keeps a repository's dependencies current: it
scans package files, finds newer versions in their registries, and opens pull requests that update
both the declared versions and the lock files. It runs across most Git platforms and package
ecosystems, and it is configured per repository with shareable presets. As a supply-chain control
it complements a scanner such as [[concepts/devops/trivy|Trivy]]: the scanner reports
known-vulnerable versions, and Renovate opens the PR that moves past them.

> [!info] Source and version
> Vendor documentation, docs version 44.194.0, fetched 2026-10-29. Renovate releases often; option
> names and defaults change between majors.

## Why It Matters

- **Outdated dependencies are a vulnerability backlog.** The fix for a reported CVE is usually "upgrade
  to the fixed version", and that upgrade is cheap only when the project is already close to current.
- **Small, frequent upgrades are safer than rare big ones.** One PR per update, each tested by CI,
  isolates the change that breaks the build; a year of skipped updates lands as one untestable jump.
- **It turns upgrading into review.** Humans approve or reject a PR instead of discovering, editing,
  and testing version bumps by hand.
- **Its main cost is noise.** Unconfigured, it can open more PRs than a team will read, so most of its
  configuration surface exists to group, schedule, and automerge.

## How It Works

Renovate splits the problem into four kinds of module, run in order:

| Module | Job | Example |
| --- | --- | --- |
| Platform | Talks to the Git host: lists repositories, clones, opens branches and PRs | GitHub, GitLab, Bitbucket, Azure DevOps, Gitea, Forgejo |
| Manager | Finds package files by name and extracts their dependencies | `npm`, `gitlabci`, `dockerfile`, `github-actions` |
| Datasource | Looks up the versions available for a dependency | `npm` registry, `docker` registry tags |
| Versioning | Validates and sorts versions and picks the compatible next one | SemVer, `docker` tag versioning |

The documentation's own example: the `gitlabci` manager finds the image `python:3.10-alpine`, the
`docker` datasource lists its tags, and `docker` versioning chooses `python:3.11-alpine` as the
compatible update.

Each run initializes the platform, discovers and filters repositories, then for each repository:

1. Initializes it and resolves its configuration (precedence: CLI, then environment, then the
   config file, then defaults).
2. Extracts dependencies for every manager, after checking base branches and known vulnerabilities.
3. Looks up updates through each dependency's datasource and versioning.
4. Writes updates: decides per update whether a branch is needed (existing branches, rebasing, the
   concurrent-PR limit), then creates the branch, commits the change, and opens the PR.
5. Finalizes: checks whether the config needs migrating and deletes stale branches.

## Running It

| Option | What it is | Notes |
| --- | --- | --- |
| Mend Renovate App | Hosted app run by Mend | GitHub.com for all or selected repositories; a GitLab.com app relaunched in July 2026, installable on groups only. Runs continuously and can open PRs at any hour. |
| Self-hosted CLI | The npm package, or pre-built images on GitHub Container Registry and Docker Hub | Runs when you schedule it (e.g. a cron job or CI pipeline); `autodiscover: true` processes every repository the bot account can reach, or list repositories explicitly |

Supported platforms: Azure DevOps, AWS CodeCommit, Bitbucket Cloud and Server, Forgejo, Gerrit
(experimental), Gitea, GitHub.com and Enterprise Server, and GitLab.com and self-managed.

## Onboarding and Configuration

When enabled on a repository, Renovate first opens a **"Configure Renovate"** onboarding PR that
adds `renovate.json` with suggested defaults, and it makes no other change until that PR is merged.
Closing the PR unmerged opts the repository out; committing a config file directly skips onboarding.

Renovate looks for its config in `renovate.json` or `renovate.json5`, under `.github/` or
`.gitlab/`, or in `.renovaterc`, `.renovaterc.json`, or `.renovaterc.json5`. A `"renovate"` key in
the root `package.json` still works but is deprecated.

**Presets** are reusable configuration, referenced through `extends`. Built-in presets such as
`config:recommended` provide defaults; an organisation keeps one shared preset in a repository and
has every repository extend it, so a policy change is one edit. When presets conflict, the last
entry in `extends` wins.

```json
{
  "extends": ["config:recommended", "security:minimumReleaseAgeNpm"],
  "packageRules": [
    {
      "matchPackageNames": ["/eslint/"],
      "groupName": "eslint",
      "schedule": ["* 0-3 * * 1"]
    }
  ]
}
```

`packageRules` apply options to the dependencies they match; here, every package with "eslint" in its
name is grouped into one PR, raised only before 04:00 on Mondays. The rule is an illustration built
from options the documentation describes, not a recommended config.

## Controlling Noise

| Lever | How | Trade-off |
| --- | --- | --- |
| Grouping | `groupName` in a package rule; `group:monorepos` (in the `:app` and `:library` presets) groups sibling packages such as `@angular/*` | Fewer PRs, but one bad package fails the whole group and delays the rest |
| Scheduling | `schedule` (cron syntax, at least hourly granularity) and `timezone` (default UTC), globally or per rule | Fewer interruptions, but branches go stale and rebases wait for the next window |
| Automerge | Merge passing updates without review (below) | Less review load; trust moves to the test suite |
| Dashboard approval | Hold some updates until approved on the Dependency Dashboard | Nothing opens unasked, but someone must check the dashboard |

The documentation's lock-file view: grouping and automerging both reduce lock-file conflicts, while
squeezing Renovate into a shorter schedule raises them, because more PRs are open at once.

## Automerge

With automerge on, Renovate merges its own update once required checks pass and the branch is up to
date with its base, one merge per target branch per run.

- **`automergeType: pr`** (default) merges the PR after checks pass.
- **`automergeType: branch`** skips the PR: a passing branch is pushed straight to the base branch,
  and a PR is opened only if tests fail. CI must run on `renovate/**` branches, and branch protection
  must allow the push.
- **`platformAutomerge`** (on by default) hands the merge to the platform's native automerge, which
  changes how merge queues and merge trains behave.

The documentation's guidance on what to automerge: updates you would merge anyway; dev-only tooling
such as linters and test runners; lock-file maintenance, the lowest-risk update; non-major
[[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] updates, commonly
excluding pre-1.0.0 packages, which may break at any version; production dependencies only behind
strong test coverage.

> [!warning] Automerge needs real checks
> Renovate will not automerge without passing status checks, and `ignoreTests: true` removes that
> safeguard entirely. Required reviews, restricted committers, and CODEOWNERS rules also block it
> silently; the PR body states whether automerge is enabled.

## Dependency Dashboard

The Dependency Dashboard is a repository issue that Renovate keeps current, listing pending updates,
closed or ignored ones (re-requested by ticking a checkbox), and deprecated or abandoned dependencies
with suggested replacements. It needs a platform whose issues support dynamic Markdown checkboxes.

Its approval workflow, `dependencyDashboardApproval`, makes Renovate wait for a tick before opening a
PR. The documentation discourages it for all updates, because the dashboard then has to be watched,
and recommends it for **major** updates instead of disabling them, so pending majors stay visible.
Vulnerability fixes are opened immediately regardless.

## Renovate and Dependabot

> [!note] Vendor comparison
> This section summarises Renovate's own comparison page; Dependabot's documentation may describe
> its capabilities differently.

| | Renovate | Dependabot |
| --- | --- | --- |
| Platforms | Most Git hosts, self-hosted on any of them | Officially GitHub and Azure DevOps |
| Grouping | Community groupings by default | Supported; groups are user-defined (automatic for security updates) |
| Scheduling | As often as allowed by default; per dependency, manager, or globally | Interval, day, time, and timezone per ecosystem |
| Dashboard | Dependency Dashboard, on by default | No equivalent |
| Hosting | Hosted app, or self-hosted CLI and images | Built into GitHub, or a GitHub Actions workflow |
| Licence | AGPL | MIT |

## Related Concepts

- [[concepts/devops/trivy|Trivy]] — finds the vulnerable dependency; Renovate opens the PR that upgrades it
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — the version contract that decides which updates are safe to automerge
- [[concepts/version_control/gitlab/gitlab_repository_security|GitLab Repository Security]] — the branch protection and approval rules that automerge has to work within

## References

- [Renovate documentation](https://docs.renovatebot.com/)
- [Renovate: Automerge configuration and troubleshooting](https://docs.renovatebot.com/key-concepts/automerge/)
- [Renovate: Bot comparison](https://docs.renovatebot.com/bot-comparison/)
