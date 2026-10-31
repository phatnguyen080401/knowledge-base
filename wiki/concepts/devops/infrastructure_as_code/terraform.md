---
title: Terraform
tags: [devops, deployment, ci-cd, terraform]
created: 2026-10-30 23:16:23
updated: 2026-10-31 10:30:24
---

# Terraform

Terraform is HashiCorp's infrastructure-as-code (IaC) tool: cloud and platform resources are declared in HCL configuration files, and Terraform computes and executes the API calls that make the real infrastructure match them, recording what it manages in a state file. It is the execution layer that tools such as [[concepts/devops/brainboard|Brainboard]] generate code for and scanners such as [[concepts/devops/trivy|Trivy]] check.

## Why It Matters

Infrastructure created by hand in a cloud console ("click-ops") has no history, no review, and no reliable way to be reproduced in a second environment. Infrastructure as code moves it into the same workflow as application code: a Git diff shows what will change, a pull request is the review, and the same configuration builds dev, staging, and production.

Terraform's particular contribution is that it is **declarative** and **provider-agnostic**. The configuration states the desired end result rather than the steps to reach it, and one language and one workflow cover AWS, Google Cloud, Azure, [[concepts/devops/kubernetes/kubernetes|Kubernetes]], DNS, monitoring vendors, and hundreds of other APIs through plug-in providers.

## Building Blocks

| Element | Role |
| --- | --- |
| **Provider** | A plug-in that translates Terraform resources into one platform's API calls (`aws`, `google`, `kubernetes`), downloaded from a registry and version-pinned |
| **Resource** | One managed object, such as a bucket, a VPC, or a DNS record; Terraform creates, updates, and destroys it |
| **Data source** | A read-only lookup of something Terraform does not manage, such as an existing network or an AMI ID |
| **Variable / output / local** | Inputs to a configuration, values it exposes to callers, and named intermediate expressions |
| **Module** | A directory of configuration called with inputs, the unit of reuse; a root module calls child modules from a path, Git, or a registry |
| **State** | The record mapping each resource address in the code to the real object's ID and last known attributes |
| **Backend** | Where state is stored and locked: a local file, or remote storage such as S3, GCS, Azure Storage, or HCP Terraform |

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  backend "gcs" {
    bucket = "acme-tf-state"
    prefix = "network/prod"
  }
}

resource "google_storage_bucket" "raw" {
  name     = "acme-raw-prod"
  location = "EU"

  lifecycle {
    prevent_destroy = true
  }
}
```

## The Core Workflow

1. **`terraform init`** downloads providers and modules and configures the backend.
2. **`terraform plan`** refreshes state against the real infrastructure, diffs it with the configuration, and prints the actions it would take: create, update in place, replace, or destroy.
3. **`terraform apply`** executes a plan, ideally a saved one (`plan -out=tfplan`, then `apply tfplan`) so that what was reviewed is exactly what runs.
4. **`terraform destroy`** removes everything the configuration manages.

Terraform builds a dependency graph from the references between resources, so a subnet that names a VPC is created after it and destroyed before it, and independent resources are handled in parallel. `depends_on` adds an ordering that no reference expresses.

> [!warning] Replace means destroy, then create
> Changing an immutable attribute, such as a database's name or a disk's type, shows as `-/+` in the plan: the existing object is destroyed and a new one created. Read every plan for replacements before applying; `lifecycle { prevent_destroy = true }` turns an accidental one on a critical resource into an error.

## State

State is what lets a declarative tool know that `google_storage_bucket.raw` in the code *is* bucket `acme-raw-prod` in the cloud. Without it, Terraform could not tell an update from a create, or know what to delete when a block is removed.

- **Remote and locked.** A team keeps state in a remote backend that locks it during an operation, so two applies cannot interleave and corrupt it; on AWS that is the [[concepts/devops/infrastructure_as_code/terraform_s3_backend|S3 backend]], locked with DynamoDB or an S3 lock file.
- **Sensitive.** State holds resource attributes in plain text, including generated passwords and keys, so the backend needs the access control and encryption described in [[concepts/data_governance/data_security|Data Security]].
- **Split by blast radius.** One state per environment and per component (network, data platform, applications) keeps plans fast and limits what a single bad apply can touch.
- **Refactored with blocks, not by hand.** `moved` blocks record renames of resource addresses, `import` blocks adopt existing infrastructure into state, and `removed` blocks stop managing an object without destroying it; each is reviewed in a plan like any other change.

**Drift** is the gap between state and reality caused by changes made outside Terraform. A plan shows it as a change Terraform would revert; `plan -refresh-only` reports it without proposing to fix it.

## Terraform in CI/CD

The common team pattern runs Terraform only from a pipeline, never from a laptop:

- On a pull request: `fmt -check`, `validate`, a misconfiguration scan (Trivy's `config` scanner, Checkov), and a `plan` posted to the review.
- On merge to the main branch: `apply` of the reviewed plan, using a pipeline identity that holds the cloud credentials, so no person needs standing write access.
- Path ownership: a `CODEOWNERS` rule on the Terraform directory, as in [[concepts/version_control/gitlab/gitlab_repository_security|GitLab Repository Security]], forces the platform team's approval.

HCP Terraform (formerly Terraform Cloud), Atlantis, Spacelift, and Brainboard package this pattern with a managed backend, policy checks, and run history.

## Licensing and OpenTofu

Terraform was released in 2014 under the open-source MPL 2.0 licence. In August 2023 HashiCorp moved new versions (1.6 onward) to the source-available Business Source License, which restricts offering competing products. The community forked the last MPL release as **OpenTofu**, now hosted by the Linux Foundation, which stays largely compatible with Terraform's language, providers, and state. IBM completed its acquisition of HashiCorp in 2025. For most internal users, the licence change does not affect running Terraform. It matters to vendors building on it and to organizations that require an OSI-approved licence.

## Alternatives

| Tool | Difference from Terraform |
| --- | --- |
| AWS CloudFormation, Azure Bicep | Single-cloud, with state managed by the provider itself |
| Pulumi | The same desired-state model, written in general-purpose languages (TypeScript, Python, Go) instead of HCL |
| Crossplane | Infrastructure as Kubernetes custom resources, reconciled continuously by a controller instead of applied on demand |
| Ansible | Configuration management of hosts' contents, usually procedural; often paired with Terraform, which provisions the hosts |

## Related Concepts

- [[concepts/devops/brainboard|Brainboard]] — a visual design layer that generates and runs Terraform, aimed at teams short of people who can write and review HCL
- [[concepts/devops/trivy|Trivy]] — scans Terraform for misconfigurations such as public buckets before `apply`, the policy gate in the pipeline above
- [[concepts/devops/infrastructure_as_code/terraform_s3_backend|Terraform S3 Backend and DynamoDB State Locking]] — the standard AWS backend in detail: lock table or lock file, force-unlock, bootstrapping, and bucket hardening
- [[concepts/devops/kubernetes/kubernetes|Kubernetes]] — commonly provisioned with Terraform (the cluster) and also managed through its provider (the objects inside it)
- [[concepts/data_governance/data_security|Data Security]] — the controls that state files, which hold secrets in plain text, and pipeline cloud credentials require
- [[concepts/version_control/gitlab/gitlab_repository_security|GitLab Repository Security]] — Code Owners and protected branches that keep infrastructure changes reviewed
- [[concepts/software_architecture/semantic_versioning|Semantic Versioning (SemVer)]] — how the `~>` constraints that pin providers and modules decide which upgrades arrive automatically

## References

- [Terraform documentation](https://developer.hashicorp.com/terraform/docs)
- [OpenTofu](https://opentofu.org/)
