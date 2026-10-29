Source: https://docs.renovatebot.com/ (fetched 2026-10-29 18:29:30)

# Renovate Docs

Clipped from the Renovate documentation site: the home page plus the key-concept pages it links to.
Each section names its page. Text is a condensed extract made with a web-fetch tool, not a verbatim
copy; JSON examples are as published.

## Home (https://docs.renovatebot.com/)

Docs version at fetch time: 44.194.0. A notice says Renovate 44 was released as a major version by
accident although its changes were non-breaking, and asks for feedback on monorepos, getting-started
problems, complexity, and wishlist items.

Renovate provides automated dependency updates, across many platforms and languages.

Why use Renovate:

- Automatic updates: pull requests that update dependencies and lock files.
- Scheduling: run on a schedule to reduce PR noise.
- Works out of the box: finds relevant package files automatically, including in monorepos.
- Customization: behaviour is controlled through configuration files.
- Shared presets: configuration can be shared as ESLint-like presets.
- Replacement PRs: proposes migrations from deprecated dependencies to community-suggested
  replacements, for most managers.
- Open source: licensed AGPL-3.0-only.

Supported platforms: Azure DevOps, AWS CodeCommit, Bitbucket Cloud, Bitbucket Server, Forgejo,
Gerrit (experimental), Gitea, GitHub (.com and Enterprise Server), GitLab (.com and CE/EE).

Users listed include Prisma, Netlify, Microsoft, Atlassian, Mozilla, Red Hat, Uber, and Buildkite.

Ways to run it: the open-source npm package; a pre-built image on GitHub Container Registry; a
pre-built image on Docker Hub; the Mend Renovate App, hosted by Mend.

## How Renovate Works (https://docs.renovatebot.com/key-concepts/how-renovate-works/)

Renovate usually clones the repository, scans package files to extract dependencies, looks up
registries for updates, applies grouping rules, and pushes branches and opens pull requests. Because
it must handle many naming and versioning conventions, it uses a separate module for each.

Modules, run in this order:

- Platform: interacts with the source-control platform and clones the repository.
- Manager: finds files by name and extracts their dependencies. Each dependency has a datasource.
- Datasource: looks up the available versions of a dependency.
- Versioning: validates and sorts the returned versions.

Example: the `gitlabci` manager finds `python:3.10-alpine`, which uses the `docker` datasource; the
datasource returns the available tags, and `docker` versioning selects `python:3.11-alpine` as the
compatible update.

Before processing repositories, Renovate initializes the platform, queries it for repositories, and
filters the list. Configuration precedence: CLI, then environment, then file, then defaults.

Per repository:

1. Initialize the repository.
2. Extract dependencies: extract base branches, check for vulnerabilities, then for each manager
   match files and extract dependencies.
3. Look up updates: for each dependency, fetch versions from the datasource, then use versioning to
   find the next valid update.
4. Write updates: for each update, decide whether a branch is needed (existing branches, rebasing,
   the concurrent limit), then create the branch, apply the update, and create the PR.
5. Finalize: check for config migration, then clean up stale branches.

## Installing and Onboarding (https://docs.renovatebot.com/getting-started/installing-onboarding/)

Hosted apps:

- Mend Renovate App for GitHub.com: install from GitHub Apps for all or selected repositories.
  Repositories without known package files are ignored; forks are skipped under "All repositories"
  and processed under "Select repositories".
- Mend Renovate App for GitLab.com: relaunched in July 2026; installable only on a Group, not a
  User; set up through the Mend Developer Platform.

Self-hosted: run as a dedicated account with the global option `autodiscover: true` to process every
repository it can access, or configure a fixed list of repositories. On Windows, set
`core.autocrlf` to `input`, or add `* text=auto eol=lf` to `.gitattributes`.

Onboarding:

1. Once enabled on a repository, Renovate opens a "Configure Renovate" pull request.
2. The PR adds `renovate.json` in the root with suggested defaults.
3. Renovate makes no other changes and opens no other PRs until the onboarding PR is merged.
4. The config can be edited on the `renovate/configure` branch; the PR description updates to match.
5. Warnings or errors must be fixed on the base branch so Renovate can regenerate the PR.
6. Merging the PR enables real dependency PRs.

Self-hosted users can enable `onboardingRebaseCheckbox`.

Config files searched, after any custom names in `configFileNames`: `renovate.json`,
`renovate.json5`, `.github/renovate.json`, `.github/renovate.json5`, `.gitlab/renovate.json`,
`.gitlab/renovate.json5`, `.renovaterc`, `.renovaterc.json`, `.renovaterc.json5`, and a `"renovate"`
section of the root `package.json` (deprecated, to be removed).

Opting out: close the onboarding PR unmerged (reversible; rename the closed PR to re-request).
Manual onboarding: commit a config file to the default branch. Reconfiguring: push a
`renovate/reconfigure` branch and open a PR; Renovate comments with the expected changes.

## Presets (https://docs.renovatebot.com/key-concepts/presets/)

Presets are reusable configuration files in JSON, JSON5, or JSONC. Built-in presets are referenced by
name; custom presets by repository location. Uses: sensible defaults, avoiding duplication across
repositories, sharing configuration, extending someone else's configuration.

```json
{
  "extends": ["config:recommended", "security:minimumReleaseAgeNpm"]
}
```

Renovate applies every listed preset; on conflict, the last preset in the `extends` array wins.
Built-in examples: `config:recommended`, `helpers:pinGitHubActionDigests`,
`security:minimumReleaseAgeNpm`. For many repositories, create one global preset and have each
repository extend it. Presets can extend other presets.

## Automerge (https://docs.renovatebot.com/key-concepts/automerge/)

Renovate can merge its own update PRs once required tests pass. It waits until tests pass and the
branch is up to date with its base, and merges only one branch or PR per target branch per run; if
others keep committing to the default branch, it may not find a gap to merge.

Prerequisites: passing status checks (projects without tests can set `"ignoreTests": true`, strongly
discouraged); branch protection must not block it (restricted committers, required PRs, required
reviews, CODEOWNERS). GitHub can allow specified actors to bypass required PRs; `autoApprove` exists
for Azure, Gerrit, and GitLab.

`automergeType`: `pr` (default) opens a PR and merges it when checks pass; `branch` pushes passing
updates directly to the base branch without a PR, opening a PR only if tests fail. `renovate/**`
branches must be included in test workflows, and branch protection must allow direct pushes.

`platformAutomerge` is on by default and uses the platform's native automerge; `false` makes
Renovate merge itself. Merge queues and merge trains behave differently depending on it.

Automerge won't happen when the PR body does not say "Automerge: Enabled", checks are missing or
failing, protections block the merge, an organization preset enables it but a repository overrides
it, or the branch is out of date.

Recommendations: automerge updates you would merge anyway; often devDependencies such as test
runners and linters; production dependencies only with strong test coverage; lock file maintenance
is the lowest-risk update to automerge; non-major SemVer updates are often automerged, commonly
excluding pre-1.0.0 packages; pair automerge with schedules; use `automergeType: branch` to reduce
notification noise where branch protection allows.

## Noise Reduction (https://docs.renovatebot.com/noise-reduction/)

Grouping: related packages in one branch/PR reduce the number of updates. The `:app` and `:library`
presets include `group:monorepos`, grouping sibling packages from known monorepos such as
`@angular/*`. Custom groups use `matchPackageNames` with `groupName`. Trade-offs: higher chance of a
broken build, harder to find the culprit, other updates in the group wait until the whole group
passes, less flexibility when one package has a major upgrade.

Scheduling: the CLI runs only when its administrator schedules it (e.g. `cron`); the Mend app runs
continuously and can open PRs at any hour. Limit with `schedule` and `timezone` (default UTC), also
per package rule, e.g. monthly `["* * 1 * *"]` or Monday before 4 AM `["* 0-3 * * 1"]`. Schedules are
parsed with `@breejs/later`; granularity is at least one hour. Infrequent schedules can leave
branches stale, because rebases wait for the next scheduled run.

Automerging reduces noise, especially `automergeType: "branch"`, and combined with schedules lets
Renovate merge updates one at a time and rebase the rest.

| Action | Effect on pull requests | Chance of lock file conflicts |
| --- | --- | --- |
| Group dependencies together | Decreases separate PRs | Decreases |
| Automerge dependencies | Decreases concurrent PRs | Decreases |
| Decrease scheduled time for Renovate | Increases concurrent PRs | Increases |

## Dependency Dashboard (https://docs.renovatebot.com/key-concepts/dashboard/)

An issue in the repository giving an overview of dependency update status, and enabling an approval
workflow. Requires a platform supporting issues with dynamic Markdown checkboxes. Enable with the
`:dependencyDashboard` preset or `"dependencyDashboard": true`; disable with
`:disableDependencyDashboard` or `false`.

Shows: deprecated-dependency warnings (registry-deprecated packages or those with a community
replacement); pending updates; closed or ignored updates, which can be re-requested by ticking a box.

The `abandonments:recommended` preset (in `config:best-practices`) sets `abandonmentThreshold` to
1 year, adds overrides for packages that look abandoned but are maintained, and blocks updates to
truly abandoned packages.

Approval (`dependencyDashboardApproval`): for all updates via `:dependencyDashboardApproval`
(discouraged for most teams; vulnerability PRs are still created immediately); for majors only:

```json
{
  "major": {
    "dependencyDashboardApproval": true
  }
}
```

or for specific packages through `packageRules` with `matchPackageNames`. Approval for majors is
preferred to disabling them, because pending updates stay visible.

## Bot Comparison (https://docs.renovatebot.com/bot-comparison/)

Renovate's own comparison with Dependabot:

| Area | Renovate | Dependabot |
| --- | --- | --- |
| Platforms | Azure, Bitbucket, Forgejo, Gitea, GitHub, GitLab, SCM-Manager, and more | Officially GitHub and Azure DevOps |
| Languages | "Managers" | "Ecosystems" |
| Grouped updates | Community-provided groupings by default | Supported, but groups must be defined (automatic for security updates) |
| Scheduling | Runs as often as allowed by default; per dependency, manager, or global | Interval, day, time, timezone per language |
| Dependency Dashboard | Yes, on by default | No equivalent |
| Licence | AGPL | MIT |
| Hosting | App or self-hosted: npm CLI, Docker images, GitHub Action, GitLab Runner, Mend options | Built into GitHub; can run as a GitHub Actions workflow |
| Changelogs | Release tags, release notes, issues | Also upstream CHANGELOG files and commits |
| Compatibility badges | Four Merge Confidence badges: Age, Adoption, Passing, Confidence | One compatibility score |
| Implementation language | TypeScript | Ruby |

Dependabot self-hosting outside GitHub is not officially supported; Renovate supports self-hosting on
all its officially supported platforms. The page's table marks monorepo grouping "Yes" for
Dependabot while its detailed section says Dependabot does not update common monorepo packages in a
single PR.
