---
title: Conventional Commits
tags: [version-control, source-history, versioning, conventional-commits, git]
sources: ["https://www.conventionalcommits.org/en/v1.0.0/"]
created: 2026-10-21 16:14:26
updated: 2026-10-22 10:11:51
---

# Conventional Commits

Conventional Commits is a lightweight convention layered on top of Git commit messages that prefixes each message with a structured type — `feat:`, `fix:`, `docs:` — so that a commit history is readable by humans *and* parseable by tools. Its purpose is to make the intent of a change explicit at the point it is recorded, which is what allows changelogs, release decisions, and publish pipelines to be derived from the history rather than maintained alongside it. It is deliberately designed to dovetail with [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]]: the type of a commit determines which version element the next release increments. The current specification is **Conventional Commits 1.0.0**.

## Why It Matters

A freeform commit log is write-only. Nobody reads it, so nothing can be built on it, so the facts it should carry — what changed, whether it breaks anyone, whether it is worth a release — get re-entered by hand into a changelog, a release note, and a version bump, where they drift apart.

Making the first line machine-readable turns the history into a source of truth, which is what the spec lists as the payoff:

- **Automatic CHANGELOG generation** — grouped by type, with no separately maintained file.
- **Automatic version bump selection** — derived from the types landed since the last tag.
- **Communicating the nature of changes** to teammates, users, and other stakeholders.
- **Triggering build and publish processes** off the fact that a releasable commit landed.
- **Lowering the barrier to contributing**, because a structured history is explorable.

There is a second-order benefit the FAQ makes explicit: when a change genuinely fits two types, the convention pressures you to split it into two commits. The discipline improves the commits themselves, not just their labels.

## Message Structure

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

| Element         | Required | Rules                                                                                     |
| --------------- | -------- | ----------------------------------------------------------------------------------------- |
| **type**        | Yes      | A noun (`feat`, `fix`, …), followed by the optional scope, optional `!`, then a colon and a space |
| **scope**       | No       | A noun naming a section of the codebase, in parentheses: `fix(parser):`                   |
| **description** | Yes      | A short summary, immediately after the colon and space                                     |
| **body**        | No       | Free-form, any number of paragraphs, beginning **one blank line** after the description    |
| **footers**     | No       | One blank line after the body; each is a token, a separator, and a value                   |

Footers follow the [git trailer](https://git-scm.com/docs/git-interpret-trailers) convention: a word token, then either `: ` or ` #`, then a value — `Reviewed-by: Z`, `Refs #133`. The token **must** use `-` in place of spaces (`Acked-by`, not `Acked by`), which is exactly what lets a parser tell the footer block apart from a multi-paragraph body. A footer's value may contain spaces and newlines; parsing stops at the next valid token/separator pair.

## The Types

Only two types are defined by the specification itself:

- **`fix:`** — patches a bug. Correlates with a **PATCH** release.
- **`feat:`** — introduces a new feature. Correlates with a **MINOR** release.

Everything else is convention, not specification. Additional types are explicitly allowed, carry **no implicit SemVer effect**, and are not mandated — teams pick a set and may change it over time. The widely used list comes from the Angular convention via [`@commitlint/config-conventional`](https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional):

| Type       | Used for                                                       |
| ---------- | -------------------------------------------------------------- |
| `build`    | Build system or external dependency changes                     |
| `chore`    | Maintenance that touches neither source behaviour nor tests     |
| `ci`       | CI configuration and pipeline changes                           |
| `docs`     | Documentation only                                              |
| `perf`     | A change that improves performance                              |
| `refactor` | A change that neither fixes a bug nor adds a feature            |
| `style`    | Formatting and whitespace, no behavioural change                |
| `test`     | Adding or correcting tests                                      |

Casing is not fixed by the spec — implementors must treat the units as case-insensitive — but consistency within a project is recommended. The one exception is `BREAKING CHANGE`, which **must** be uppercase.

## Breaking Changes

A breaking change may ride on a commit of *any* type, and must be signalled in one of two places:

1. **A `!` before the colon** in the type/scope prefix — `feat!:` or `feat(api)!:`. When `!` is used, the footer may be omitted and the description itself describes the break.
2. **A `BREAKING CHANGE: <description>` footer** — uppercase, colon, space, description. `BREAKING-CHANGE` is a synonym when used as a footer token.

Either signal correlates with a **MAJOR** release, regardless of the commit's type. Using both is valid and is the clearest form for a consequential break:

```text
feat!: drop support for Node 6

BREAKING CHANGE: use JavaScript features not available in Node 6.
```

## Worked Examples

```text
docs: correct spelling of CHANGELOG
```

```text
feat(lang): add Polish language
```

```text
feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in config file is now used for extending other config files
```

```text
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Reviewed-by: Z
Refs: #123
```

## Relationship to Semantic Versioning

The mapping is the whole point of the convention, and it is mechanical:

| Commit                              | Release |
| ----------------------------------- | ------- |
| `fix:`                              | PATCH   |
| `feat:`                             | MINOR   |
| Any type with `!` or `BREAKING CHANGE` | MAJOR |
| Any other type, with no break       | None    |

This is what lets a release tool compute the next version from `git log` alone. Note the direction of the dependency: Conventional Commits needs SemVer to mean anything, but SemVer does not need Conventional Commits — it only needs *some* way of classifying a change as breaking, additive, or corrective. The same prerequisite applies to both: until a project has declared a public API, no one can say whether a commit breaks it.

## Practical Guidance from the FAQ

- **Start before 1.0.0.** Behave as though you have already released — somebody is already using the software and wants to know what broke.
- **One commit, one type.** If a change fits two types, split it. The constraint is a feature.
- **Fixing a wrong type:** before merge or release, `git rebase -i` to edit the message. After release, cleanup depends on your tooling — and a non-conforming commit is not a catastrophe, it simply becomes invisible to the tools that read the history.
- **Not every contributor must comply.** With a squash-merge workflow, a maintainer writes the conforming message at merge time, so casual contributors carry no extra burden.
- **Reverts are undefined.** The spec deliberately declines to specify revert behaviour, leaving it to tooling authors. The recommended shape is a `revert` type with a footer naming the reverted SHAs:

  ```text
  revert: let us never again speak of the noodle incident

  Refs: 676104e, a215868
  ```

- **Extensions are encouraged**, and should themselves be versioned with SemVer.

## Specification Keywords

The spec is written in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt) language, so the distinction between its rules matters when implementing a parser. The MUSTs are few: a type prefix with a terminal colon and space, a description immediately following it, blank-line separation before body and footers, hyphenated footer tokens, uppercase `BREAKING CHANGE`, and a breaking change signalled in either the prefix or a footer. Nearly everything else — scope, body, footers, extra types — is MAY.

## Related Concepts

- [[concepts/version_control/git|Git]] — the history this convention formats: the commit object whose message carries the type, and the `rebase -i` and squash-merge mechanics the FAQ's fix-a-wrong-type advice relies on
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — the release-numbering scheme this convention feeds; commit types map directly onto PATCH, MINOR, and MAJOR
- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — the public API whose breakage a `BREAKING CHANGE` footer is declaring
- [[concepts/data_architecture/data_architecture|Data Architecture]]
- [[concepts/software_architecture/software_architecture|Software Architecture]]

## References

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) — the specification, examples, and FAQ
- [git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers) — the trailer convention the footer format is inspired by
- [`@commitlint/config-conventional`](https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional) — the Angular-derived type list the spec cites as an example
