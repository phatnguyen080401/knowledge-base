---
title: Semantic Versioning (SemVer)
tags: [software-architecture, versioning, compatibility-contracts]
created: 2026-10-20 14:50:33
updated: 2026-10-21 14:23:04
---

# Semantic Versioning (SemVer)

Semantic Versioning is a specification for numbering software releases as `MAJOR.MINOR.PATCH`, where each increment carries a defined meaning about compatibility: MAJOR for backward-incompatible changes to the public API, MINOR for backward-compatible additions, PATCH for backward-compatible bug fixes. It turns a version string from an arbitrary label into a machine-readable compatibility contract, which is what makes automated dependency resolution possible at all. The current specification is **SemVer 2.0.0**, authored by Tom Preston-Werner.

## Why It Matters

Without a formal scheme, a version number tells a consumer nothing, and dependency specifications become a guess between two failure modes the spec names directly:

- **Version lock** — dependencies pinned so tightly that upgrading one package forces a new release of every package that depends on it.
- **Version promiscuity** — dependencies specified so loosely that a future release silently breaks you.

"Dependency hell" is being trapped between the two. SemVer escapes it by letting a consumer express an interval such as "`>=3.1.0` and `<4.0.0`" and trust that everything in that range is compatible. The guarantee is social, not enforced by tooling — it holds only because the publisher declared they follow the spec and then did.

The prerequisite is the one most projects skip: **you must declare a public API.** Until you say which behaviour consumers may depend on, there is no way to classify a change as breaking or not, and the version number means nothing.

## The Core Rules

A normal version is `X.Y.Z`, all non-negative integers, no leading zeroes, each element increasing numerically — so `1.9.0 → 1.10.0 → 1.11.0`, not `1.9.0 → 1.91.0`.

| Increment | When                                                                                                            | Resets        |
| --------- | --------------------------------------------------------------------------------------------------------------- | ------------- |
| PATCH `Z` | Backward-compatible bug fixes only — an internal change that corrects incorrect behaviour                        | —             |
| MINOR `Y` | Backward-compatible functionality added to the public API. **Required** when any public API is marked deprecated. May also be bumped for substantial internal improvements | PATCH → 0     |
| MAJOR `X` | Any backward-incompatible change to the public API                                                               | MINOR, PATCH → 0 |

Two further rules do most of the practical work:

- **Released versions are immutable.** Once `1.4.2` is published, its contents must never change. A fix is a new version, always — this is what makes a lockfile meaningful.
- **`0.y.z` means nothing is stable.** Major version zero is the initial development phase: anything may change at any time, and consumers should not assume compatibility. `1.0.0` is the moment you commit to a public API. The spec's guidance is blunt — if your software is in production, or users already depend on a stable API, you should probably already be at `1.0.0`.

## Pre-release and Build Metadata

Two optional suffixes extend the `X.Y.Z` core:

- **Pre-release** — a hyphen followed by dot-separated identifiers of ASCII alphanumerics and hyphens: `1.0.0-alpha`, `1.0.0-alpha.1`, `1.0.0-rc.1`. It signals the release is unstable and may not satisfy the compatibility its core version implies. A pre-release always sorts **below** its associated normal version.
- **Build metadata** — a plus sign followed by dot-separated identifiers: `1.0.0+20130313144700`, `1.0.0-beta+exp.sha.5114f85`. It is **ignored entirely when comparing versions**, so two releases differing only in build metadata have equal precedence. Never encode anything consumers must distinguish here.

## Precedence

Comparison proceeds left to right — major, then minor, then patch, numerically — and stops at the first difference. Build metadata never participates.

When the core is equal, a pre-release loses to the normal version (`1.0.0-alpha < 1.0.0`). Between two pre-releases, identifiers are compared one at a time:

1. All-numeric identifiers compare numerically.
2. Identifiers containing letters or hyphens compare lexically in ASCII order.
3. A numeric identifier always ranks **below** a non-numeric one.
4. If all shared identifiers are equal, the version with **more** identifiers ranks higher.

The specification's worked example:

```text
1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta
            < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0
```

Note `beta.2 < beta.11` — numeric identifiers compare as numbers, which is precisely why naive string sorting of version numbers is wrong.

## Validating a Version String

The spec publishes a reference regular expression; the named-group variant is:

```text
^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$
```

A numbered-capture-group variant is provided for engines without named groups. The spec also defines a full Backus–Naur Form grammar, which is the authority when the regex and your intuition disagree.

## Common Mistakes

- **Treating `v1.2.3` as a semantic version.** It is not. `1.2.3` is the version; the `v` is an English-language prefix conventionally used for tags, as in `git tag v1.2.3`. Strip it before parsing.
- **Shipping a breaking change as a minor or patch release.** The remedy is never to re-publish the offending version — releases are immutable. Release a new version that restores compatibility, document the broken one, and tell your users.
- **Removing functionality without a deprecation window.** Deprecation must ship in a MINOR release first and stay through at least one release before the MAJOR that removes it, so consumers have a version in which both the warning and the old behaviour exist.
- **Encoding meaning in build metadata.** It is ignored by precedence, so a consumer's resolver cannot act on it.
- **Sorting versions as strings.** `1.10.0` sorts before `1.9.0` lexically and after it semantically.
- **Staying on `0.y.z` to avoid commitment.** If people depend on it in production, the `0` is no longer honest. Conversely, fear of reaching `42.0.0` is not a reason to hide breaking changes — the cost of a MAJOR bump is the point, because it forces the cost/benefit of a breaking change to be weighed.
- **Assuming a dependency upgrade needs a bump.** Updating your own dependencies without changing your public API is compatible. Whether it is PATCH or MINOR depends on whether it fixed a bug or enabled new functionality.

## Where It Shows Up in Data Work

SemVer is not an application-code concern alone — most of the data stack depends on it:

- **Package and adapter pinning.** dbt packages declare ranges (`version: [">=0.10.0", "<0.11.0"]`), and [[concepts/data_engineering/dbt/dbt_bigquery_adapter|dbt-bigquery]] and [[concepts/data_engineering/dbt/dbt_databricks_adapter|dbt-databricks]] track dbt Core's minor version, so core and adapter must be upgraded together. A lockfile such as `package-lock.yml` is what freezes a range to an exact resolved version.
- **Release artifacts.** In [[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]], an immutable image tag plays the same role a published version does: rolling back means deploying an older tag, never mutating an existing one.
- **API contracts.** The versioning discipline [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] calls for — `/v2/...` paths, schema registries, breaking-change monitoring — is SemVer's MAJOR rule applied to a wire contract.
- **Model and schema versions.** dbt's model versions let a breaking change ship as `v2` while `v1` serves existing consumers through a deprecation window: the same deprecate-then-remove sequence the spec prescribes.

## Related Concepts

- [[concepts/software_architecture/software_architecture|Software Architecture]] — versioning is how an architectural boundary stays safe to depend on while the component behind it changes
- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — the public API whose compatibility a version number describes, and where breaking changes become visible to consumers
- [[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] — pins packages and adapters by version range and ships breaking model changes as explicit versions
- [[concepts/data_governance/metadata_management|Metadata Management]] — schema and contract registries are where published versions are catalogued and breaking changes detected

## References

- [Semantic Versioning 2.0.0](https://semver.org/) — the specification, BNF grammar, reference regexes, and FAQ
- [RFC 2119](https://tools.ietf.org/html/rfc2119) — the meaning of MUST, SHOULD, and MAY as used throughout the spec
