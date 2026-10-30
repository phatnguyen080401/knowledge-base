---
title: Trivy
tags: [devops, supply-chain-security, ci-cd, trivy, overview]
sources: ["https://trivy.dev/", "https://trivy.dev/docs/latest/guide/"]
created: 2026-10-21 15:07:21
updated: 2026-10-30 12:31:16
---

# Trivy

Trivy is an open-source (Apache-2.0, Go) security scanner from Aqua Security that inspects a target — a container image, a source repository, a filesystem, a VM image, an SBOM, or a live Kubernetes cluster — and reports known vulnerabilities, infrastructure-as-code misconfigurations, hardcoded secrets, and license problems from a single binary. Its purpose in a delivery pipeline is to make "is this artifact safe to ship?" a command that exits non-zero, which is the enforcement half of the quality attributes named in [[concepts/software_architecture/software_architecture|Software Architecture]].

> [!info] Scope of this note
> A tool overview written from the project site and user guide, to record what Trivy is *for* and where it belongs in a pipeline. It is not a configuration reference; the per-flag detail lives in the docs linked at the bottom.

## The Problem It Targets

Most of the code in a deployed artifact was written by someone else. A container image carries an OS distribution, its package manager's packages, and the application's dependency tree; the infrastructure around it is declared in Terraform, Helm charts, and Kubernetes manifests that are equally capable of being wrong. The questions that follow — which of those components has a published CVE, is this S3 bucket public, did someone commit an API key — were historically answered by four different tools with four different report formats, and often only by a commercial platform.

Trivy's premise is one scanner covering all of it, runnable locally, in CI, and against a running cluster, producing the same findings in each place.

## What It Scans

Two independent axes: **what you point it at** (target) and **what it looks for** (scanner).

| Target | Command | Typical use |
| --- | --- | --- |
| Container image | `trivy image nginx:1.27` | Gate the image before it is pushed or deployed |
| Filesystem / project | `trivy fs .` | Scan a checkout, including lockfiles and IaC |
| Code repository | `trivy repo <url>` | Scan a remote repository without cloning it yourself |
| Configuration / IaC | `trivy config ./infra` | Terraform, CloudFormation, ARM, Kubernetes, Helm, Dockerfiles, Ansible |
| Kubernetes cluster | `trivy k8s` | Scan live workloads and cluster configuration |
| VM image | `trivy vm <image>` | AMIs and VM disk images |
| SBOM | `trivy sbom sbom.json` | Re-scan a previously generated bill of materials as new CVEs appear |

| Scanner | Finds |
| --- | --- |
| **Vulnerability** | Known CVEs in OS packages and language dependencies, with fixed-version information |
| **Misconfiguration** | Insecure IaC and Dockerfile settings, checked against built-in rules and custom Rego policies |
| **Secret** | Credentials, tokens, and keys committed into files or baked into image layers |
| **License** | Package licenses, so copyleft or unapproved terms surface before legal does |
| **Cryptographic asset** | Cryptographic material and usage inventoried for post-quantum and compliance work |

Coverage is deliberately broad: most mainstream Linux distributions including the distroless and Wolfi/Chainguard families, and the dependency manifests of Go, Java, Node.js, Python, Ruby, Rust, PHP, .NET, C/C++, Dart, Elixir, Swift, and Julia.

## Supply-Chain Features

- **SBOM generation and consumption.** Produce CycloneDX or SPDX from an image or a project (`--format cyclonedx`), and scan an SBOM someone else produced. The value is re-scanning: the artifact does not change, the CVE database does.
- **Attestations.** Signed vulnerability-scan records and SBOM attestations via Cosign, optionally published to Rekor, so a scan result is a verifiable claim attached to the artifact rather than a log line in a CI job.
- **VEX.** Vulnerability Exploitability eXchange documents — from a local file, a VEX repository, or an attestation — let an upstream or your own security team assert that a CVE is *not exploitable in this context*, suppressing it with a recorded justification instead of an untracked ignore.
- **Compliance reports.** Built-in compliance report formats, plus custom ones, to map raw findings onto a control framework.

## How It Runs

- **One static binary, no server required.** It downloads a vulnerability database (distributed as an OCI artifact) and caches it locally.
- **Client/server mode.** `trivy server` holds the database centrally and thin clients query it — the usual answer when many CI runners would otherwise each download it.
- **Air-gapped operation.** The databases can be self-hosted and the scanner pointed at an internal registry.
- **CI integrations.** GitHub Actions, GitLab CI, CircleCI, Bitbucket Pipelines, Azure DevOps, AWS CodePipeline, and reporting into AWS Security Hub. The gate itself is just an exit code:

```bash
# Fail the build only on fixable high/critical findings
trivy image --exit-code 1 --ignore-unfixed --severity HIGH,CRITICAL myapp:1.4.2
```

- **Noise control.** Severity filters, `--ignore-unfixed`, a `.trivyignore` file, path skipping, and VEX — in roughly that order of how defensible each is to a reviewer.
- **Extensibility.** Custom misconfiguration checks in Rego (the Open Policy Agent language), plus a plugin and module system.

## How to Think About It

Judgement, not documentation: Trivy is the **default first scanner**, because the cost of adding it is one CI step and the licence is permissive. It is strongest as a *build-time gate* on artifacts you are about to publish and as a *standing re-scan* of artifacts already published, which is the case SBOMs exist to serve.

Two scoping facts decide whether it is enough:

- **It is not a SAST tool.** It finds flaws in your *dependencies*, *configuration*, and *committed secrets* — not logic bugs in the code you wrote. Pair it with a source-analysis tool rather than expecting it to replace one.
- **It reports, it does not prioritize.** A first scan of a mature image routinely returns hundreds of findings, most of them unfixable or unreachable. Adoption fails when the gate is set to "zero vulnerabilities" on day one; it succeeds when the gate starts at fixable criticals and the backlog is worked down with VEX and base-image changes.

Aqua's earlier standalone IaC scanner, tfsec, has been folded into Trivy's misconfiguration scanner, so a toolchain that integrates tfsec — [[concepts/devops/brainboard|Brainboard]] among them — is integrating the same check corpus by its older name.

## Related Concepts

- [[concepts/software_architecture/software_architecture|Software Architecture]] — security posture as a structural property, and fitness functions as the general form of a CI gate like this one
- [[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]] — a concrete pipeline with exactly the image-build step a Trivy gate belongs in
- [[concepts/devops/brainboard|Brainboard]] — the design-time counterpart: the same IaC checks applied while the infrastructure is being drawn rather than after it is committed
- [[concepts/data_governance/data_security|Data Security]] — what the leaked credential a secret scan catches actually exposes, and the controls behind it
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — why "upgrade to the fixed version" is rarely free, and how the version range determines whether it is
- [[concepts/devops/renovate_docs|Renovate]] — the remediation half: opens the upgrade PRs for the vulnerable dependencies a scan reports
- [[concepts/devops/kubernetes/kubernetes|Kubernetes]] — the cluster `trivy k8s` scans, and the manifests and Helm charts its misconfiguration checks cover

## References

- [Trivy](https://trivy.dev/) — project site
- [Trivy User Guide](https://trivy.dev/docs/latest/guide/) — targets, scanners, coverage, supply-chain features, and configuration
- [aquasecurity/trivy](https://github.com/aquasecurity/trivy) — source, releases, and issue tracker
