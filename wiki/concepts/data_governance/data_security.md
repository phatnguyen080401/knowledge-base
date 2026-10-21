---
title: Data Security
tags: [data-governance, data-security, access-control]
created: 2026-09-22 09:11:46
updated: 2026-10-21 15:10:31
---

# Data Security

Data security is the set of controls that protect data from unauthorized access, disclosure, alteration, and destruction, across its whole lifecycle from collection to deletion. It is the enforcement arm of [[concepts/data_governance/data_governance|Data Governance]]: governance decides who *should* have access to what, and security is the machinery that makes that decision real rather than aspirational.

> [!note] Scope
> This note covers engineering practice for data platforms. It is not legal advice, and regulatory obligations vary by jurisdiction, industry, and the specific data involved.

## Why It Matters

- **Breach costs are asymmetric.** The engineering cost of masking a column is trivial; the cost of disclosing that column is regulatory, reputational, and unbounded.
- **Access tends to accumulate.** Permissions get granted for a project and never revoked. Without deliberate review, every platform drifts toward everyone having access to everything.
- **Controls must survive copying.** Data that is protected in the source system and unprotected in the warehouse copy is not protected. Security has to follow the data through the pipeline.
- **It is a governance failure mode, not just a security one.** Over-restriction is equally damaging: analysts who cannot get data build shadow copies on laptops, which is strictly worse than granting access properly.

## The Three Objectives

The classic CIA triad, phrased for data platforms:

- **Confidentiality** — only authorized parties can read it. Access control, encryption, masking.
- **Integrity** — it cannot be altered undetectably. Transaction guarantees (see [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]]), checksums, immutable audit logs, append-only storage.
- **Availability** — authorized parties can actually get it when needed. Backups, replication, recovery testing.

These trade against each other. Aggressive encryption and key rotation improve confidentiality and can threaten availability if key management fails.

## Classification: The Prerequisite

Nothing else can be automated until data is classified, because every downstream policy keys off the classification tag.

A typical scheme has a **sensitivity axis** — public, internal, confidential, restricted — and a **regulatory axis** marking categories such as PII (personally identifiable information), PHI (health), PCI (cardholder), and financial or trade-secret data. A column can carry both.

Classification only scales when it is metadata attached to the asset and propagated through lineage, which is why it belongs with [[concepts/data_governance/metadata_management|Metadata Management]]. The crucial property is **inheritance**: if a column tagged `pii` flows into a derived table, the derived column should inherit the tag automatically. Classification that stops at the raw layer protects nothing, because analysts query the derived layer.

## Access Control

**Models:**

| Model | Decision basis | Strength | Weakness |
| --- | --- | --- | --- |
| **RBAC** (role-based) | The role you hold | Simple, auditable, widely supported | Role explosion as exceptions accumulate |
| **ABAC** (attribute-based) | Attributes of user, resource, and context | Expresses fine-grained policy compactly | Harder to reason about and to audit |
| **Policy-tag-based** | Classification tag on the column | Scales with the data, not the org chart | Depends entirely on classification coverage |

**Principles that matter in practice:**

- **Least privilege** — grant the minimum needed, for the minimum time. Default-deny, not default-allow.
- **Grant to groups, never to individuals.** Individual grants are invisible at review time and outlive the person's need for them.
- **Separate duties.** The identity that deploys a pipeline should not be the identity that runs it with data access; [[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]] works through exactly this deployer/runtime split.
- **Review access periodically.** Recertification campaigns are tedious and are the only thing that reverses permission accumulation.

**Warehouse-specific mechanisms:** row-level security (a predicate restricting which rows a principal sees), column-level security (policy tags gating specific columns), and authorized or secure views (granting access to a view's results without granting access to its underlying tables). The last is the standard way to expose an aggregate while keeping the detail private, and it is how a [[concepts/data_architecture/semantic_layer|Semantic Layer]] can enforce access centrally.

## Encryption

- **At rest** — effectively universal and usually on by default in cloud platforms. It defends against stolen disks and improperly decommissioned hardware. It does *not* defend against an attacker with valid credentials, which is the realistic threat.
- **In transit** — TLS everywhere. Note that some protocols provide none of their own: the [[concepts/software_architecture/fix_protocol|FIX Protocol (Financial Information eXchange)]] has no native encryption or real authentication, so it must be secured at the transport and network layers.
- **In use** — confidential computing and enclaves protect data during processing. Still specialized.

**Key management is the real control.** Platform-managed keys are simplest; customer-managed keys (CMEK) let you hold the kill switch, since destroying the key makes the data unrecoverable; customer-supplied or held-outside keys (BYOK/HYOK) go further at significant operational risk. The [[concepts/data_engineering/dbt/dbt_bigquery_adapter|dbt-bigquery Adapter]] exposes `kms_key_name` so models can be materialized under a customer-managed key.

> [!warning] "Encrypted at rest" is not a compliance answer
> It is table stakes and addresses a narrow threat. If an analyst with legitimate credentials can `SELECT` a plaintext card number, encryption at rest has done nothing for you.

## De-identification Techniques

| Technique | What it does | Reversible | Preserves analysis | Typical use |
| --- | --- | --- | --- | --- |
| **Masking** | Replaces or redacts on read (`****1234`) | No | Partially | Support staff viewing records |
| **Tokenization** | Swaps the value for a token; mapping held in a secure vault | Yes, with vault access | Joins still work | Payment card data |
| **Pseudonymization** | Replaces identifiers with consistent surrogate keys | Yes, with the key | Yes | Analytics on personal data |
| **Hashing** | One-way digest, ideally salted | No | Equality joins only | Matching without storing identifiers |
| **Generalization** | Reduces precision (age → age band, postcode → region) | No | Coarsely | Shared datasets |
| **Aggregation** | Publishes only group-level results | No | Group level only | Public reporting |
| **Differential privacy** | Adds calibrated noise with a formal privacy budget | No | Statistically, within bounds | High-sensitivity release |

Two cautions. **Pseudonymized data is still personal data** under most privacy regimes, because re-identification remains possible — it reduces risk, it does not remove the obligation. And **unsalted hashing of a low-cardinality field is not anonymization**: an attacker can hash every possible value and invert it, which defeats hashed email addresses and national ID numbers.

## Auditing and Monitoring

Access logging answers "who read what, when" and is the only way to detect misuse by a credentialed insider. Logs must be immutable and stored outside the control of the people they audit. Beyond raw logging, useful signals include anomalous volume (a service account suddenly scanning a whole table), first-time access to sensitive assets, failed authorization spikes, and exports to unmanaged destinations. Query history views that drive cost monitoring — see [[concepts/data_engineering/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]] — carry much of this signal already.

## Lifecycle and Privacy Obligations

- **Retention and deletion.** Data kept past its purpose is pure liability. Retention schedules must be enforced by the platform, not by intention.
- **Right to erasure.** Deleting a person on request requires knowing every place they appear — which is a lineage problem ([[concepts/data_governance/metadata_management|Metadata Management]]) and an identity problem ([[concepts/data_governance/master_data_management|Master Data Management (MDM)]]). It also collides with immutable and append-only storage, which must be designed for in advance rather than discovered at request time.
- **Purpose limitation and minimization.** Collect only what is needed, use it only for the declared purpose. The cheapest security control is not holding the data.
- **Residency.** Some data may not physically leave a jurisdiction, which constrains region choice and replication topology.

## Pipeline-Specific Concerns

- **Secrets never live in code or in a repository.** Use a secret manager, or better, keyless federation such as workload identity so no long-lived credential exists at all.
- **Non-production environments are the usual leak.** Copying production data into dev for "realistic testing" quietly replicates the sensitive data into a weakly controlled environment. Mask or synthesize instead.
- **Logs and error messages leak.** A stack trace or a debug log containing row contents bypasses every column-level control you configured.
- **Guard the egress path.** Reverse ETL, BI extracts, and notebook downloads move governed data into ungoverned places.

## Common Pitfalls

- **Perimeter thinking.** Assuming anything inside the warehouse is safe because the network is private. Credentialed insiders and compromised service accounts are the realistic threat.
- **Classifying only raw data.** Analysts work in the derived layers; unpropagated tags protect nothing.
- **Over-restriction producing shadow data.** When legitimate access is too hard, people extract to spreadsheets. The result is less secure than a well-governed grant.
- **Service accounts with broad, permanent privileges.** They are rarely reviewed and are the most attractive target on the platform.
- **Treating security as a launch gate rather than a lifecycle.** Permissions, classifications, and threat models all drift.

## Related Concepts

- [[concepts/data_governance/data_governance|Data Governance]] — decides who should have access to what; security enforces it
- [[concepts/data_governance/data_stewardship|Data Stewardship]] — stewards classify data and approve access requests for their domain
- [[concepts/data_governance/metadata_management|Metadata Management]] — classification tags and lineage are the metadata that make security policy automatable
- [[concepts/data_governance/master_data_management|Master Data Management (MDM)]] — erasure and subject-access requests are unanswerable without resolved entity identity
- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — every interface is an access point requiring authentication, encryption, and rate limiting
- [[concepts/data_architecture/semantic_layer|Semantic Layer]] — a central place to enforce row- and column-level rules rather than duplicating them per consumer
- [[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]] — a worked least-privilege split between deployer and runtime identities
- [[concepts/devops/trivy|Trivy]] — the scanner that catches the committed credential, the vulnerable dependency, and the public-by-default bucket before they reach an environment
