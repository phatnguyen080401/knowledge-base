---
title: Terraform S3 Backend and DynamoDB State Locking
tags: [devops, deployment, concurrency-control, terraform, s3, dynamodb]
created: 2026-10-31 10:30:24
updated: 2026-10-31 11:34:33
---

# Terraform S3 Backend and DynamoDB State Locking

The S3 backend stores [[concepts/devops/infrastructure_as_code/terraform|Terraform]] state as an object in an Amazon S3 bucket and, classically, uses a DynamoDB table as a lock so that only one `plan` or `apply` can write that state at a time. It is the standard remote backend for teams on AWS. Since Terraform 1.10, S3 can hold the lock itself, and the DynamoDB option is deprecated.

## Why It Matters

Local state breaks as soon as two people or a person and a pipeline run Terraform: each has a different copy, and the last writer silently discards the other's changes. A shared, locked backend fixes both halves of that problem.

- **Shared:** the S3 object is the single copy every run reads and writes.
- **Locked:** a run must take the lock before touching the state and release it afterwards. A second run blocks or fails rather than racing the first, the pessimistic form of [[concepts/software_architecture/concurrency_and_parallelism#Concurrency Control|Concurrency Control]].

Sharing without locking only moves the race into the bucket. Every Terraform run does read, compute, call APIs, write. S3 has no compare-and-swap on that write, so two overlapping runs both succeed and the later one wins.

## Running Without a Lock

### Why production runs overlap

Concurrent runs are the normal case in a busy production repository, not an edge case:

- Two pull requests merge minutes apart, and the pipeline starts an `apply` for each.
- A scheduled drift-detection `plan` runs while a deploy is applying.
- An engineer runs a hotfix `apply` from a laptop during an incident, while the pipeline is mid-run.
- Someone runs `terraform state rm` or `state mv` to refactor while another run is in progress.

Pipeline concurrency settings, such as GitLab's `resource_group` or GitHub Actions' `concurrency`, serialize the pipeline's own jobs. They cannot see a laptop or a second pipeline, so they complement the state lock rather than replace it.

### What goes wrong

The core failure is a **lost update**. Here two runs start from state serial 7:

| Time | Run A (pipeline) | Run B (engineer) |
| --- | --- | --- |
| 1 | Reads state serial 7 | |
| 2 | | Reads state serial 7 |
| 3 | Creates an RDS instance | |
| 4 | | Creates a security group |
| 5 | Writes serial 8: serial 7 plus the RDS instance | |
| 6 | | Writes serial 8: serial 7 plus the security group, **overwriting A's write** |

Both applies report success. The state now holds the security group but not the database. Several problems follow from that:

- **Orphaned resources.** The [[concepts/cloud_computing/aws/rds/amazon_rds|RDS]] instance still runs and costs money, but Terraform no longer knows it exists. It will never be updated, tagged, or destroyed by the code, and nobody notices until a cost or security review finds it.
- **Duplicates or failed applies.** The next run sees the database in the code and not in state, so it tries to create it again. A fixed name fails with "already exists" and blocks every later deploy. A generated name produces a second, silent copy.
- **Interleaved changes to the same resource.** If both runs touch one resource, such as a security group's rules or an autoscaling group's size, the API calls interleave. The real infrastructure ends up in a state that neither plan showed and nobody reviewed.
- **Destroy racing apply.** A `destroy` or a replacement in one run can delete what the other run is configuring, leaving half-built infrastructure in production.

S3 replaces an object in a single write, so the file is never left half-written. The damage is that one complete, valid state silently discards another. That is worse than a corrupt file, because nothing fails at the moment it happens.

> [!important] The failure is silent and found later
> Without a lock, both runs succeed. The mismatch shows up on a later run, or in a bill or an outage, often days later and to someone else. Recovering means state surgery under pressure: `terraform import` for the orphans, `terraform state rm` for anything gone, or rolling back to an earlier version of the state object. Those versions only exist if bucket versioning was enabled.

### What the lock buys

With locking, run B's first step fails with "Error acquiring the state lock" and names run A, its operation, and its user. B waits, retries, or stops, then plans again against A's result. Terraform takes the lock by default for every command that can write state: `plan`, `apply`, `destroy`, `import`, and the `state` subcommands. `-lock=false` turns it off, and it has no place in a production pipeline.

## Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "acme-tf-state"
    key            = "network/prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
    dynamodb_table = "terraform-locks"   # classic locking, deprecated since 1.11
    # use_lockfile = true                # S3-native locking, Terraform 1.10+
  }
}
```

| Argument | Role |
| --- | --- |
| `bucket` / `key` | Where the state object lives; `key` is the path, conventionally one per component and environment |
| `region` | The bucket's region |
| `encrypt` / `kms_key_id` | Server-side encryption of the state object, with a customer-managed KMS key if given |
| `dynamodb_table` | The lock table for classic locking |
| `use_lockfile` | Lock with a `.tflock` object written beside the state, instead of DynamoDB |
| `workspace_key_prefix` | Prefix for non-default workspaces; their state lands at `env:/<workspace>/<key>` by default |
| `assume_role` | A role Terraform assumes to reach the bucket, typically in a separate state or tooling account |

> [!warning] The backend block cannot use variables
> Backend settings are read during `terraform init`, before variables exist. To vary them per environment, leave the values out of the block and pass them at init, with `terraform init -backend-config=prod.s3.tfbackend`. This is called partial configuration.

## How DynamoDB Locking Works

The table needs one thing: a partition key named exactly `LockID`, of type String. On-demand capacity is enough, since a lock costs a few writes per run.

1. Before a state-changing operation, Terraform performs a conditional `PutItem` with `LockID = "<bucket>/<key>"`. The write succeeds only if no item with that ID exists, so exactly one contender wins.
2. The item's `Info` attribute records who holds the lock: a lock ID, the operation, the user and host, the Terraform version, and the time.
3. A second run that finds the item fails with "Error acquiring the state lock" and prints that record, or keeps retrying for as long as `-lock-timeout=5m` allows.
4. When the operation finishes, Terraform deletes the item.

The table also holds a second item per state, `<bucket>/<key>-md5`, with the digest of the last state written. Terraform compares it with the object it reads, which caught stale reads from when S3 was only eventually consistent. S3 has been strongly consistent since December 2020.

> [!warning] A crashed run leaves the lock behind
> If a run is killed mid-apply, the lock item stays, and every later run fails to acquire it. First confirm that no run is still active, then remove the lock with `terraform force-unlock <LOCK_ID>`, using the ID from the error message. Never force-unlock a run that is still going: that is exactly the race the lock exists to prevent.

## S3-Native Locking

Terraform 1.10 added `use_lockfile = true`. The lock is a `<key>.tflock` object created with an S3 conditional write (`If-None-Match`), so the create fails if the object already exists. Terraform 1.11 made it generally available and deprecated `dynamodb_table`.

- **New configurations** need only the bucket. There's no table to create or pay for, and no table permissions to grant.
- **Migrating:** set both `use_lockfile = true` and `dynamodb_table` for a transition period, so that runs on either setting see each other's locks. Then remove `dynamodb_table`, and the table once nothing uses it.
- **Permissions:** the role needs `s3:PutObject` and `s3:DeleteObject` on the `.tflock` key as well as on the state key.

OpenTofu offers the same S3 lock-file option. Many existing codebases and tutorials still use the DynamoDB pattern, so it is worth recognizing even where it is no longer the recommended default.

## Bootstrapping and Hardening

The bucket and table must exist before any configuration can use them. A common approach is a small, separate bootstrap configuration that creates them with local state, after which that state is moved into the new bucket with `terraform init -migrate-state`. Some teams create them with a CloudFormation template or a one-off script instead.

State holds secrets in plain text, so the bucket needs the controls described in [[concepts/data_governance/data_security|Data Security]]:

- **Versioning on**, so that a corrupted or wrongly applied state can be rolled back to an earlier object version.
- **Block Public Access** and a bucket policy that denies non-TLS requests.
- **SSE-KMS encryption**, with key access limited to the roles that run Terraform.
- **Least-privilege IAM:** `s3:ListBucket` on the bucket; `s3:GetObject` and `s3:PutObject` on the state keys; and either `dynamodb:DescribeTable`, `GetItem`, `PutItem`, and `DeleteItem` on the table, or `s3:DeleteObject` on the lock file.
- **`prevent_destroy`** on the bucket and table resources in the bootstrap configuration.

[[concepts/devops/trivy|Trivy]]'s misconfiguration checks flag an unencrypted or unversioned bucket among others, which makes them a useful pull-request gate on the bootstrap code.

## Related Concepts

- [[concepts/devops/infrastructure_as_code/terraform|Terraform]] — the parent tool note: what state is and why a team needs it remote and locked
- [[concepts/software_architecture/concurrency_and_parallelism|Concurrency and Parallelism]] — the mutex and pessimistic-locking ideas that the lock item and the lock file implement across machines
- [[concepts/data_governance/data_security|Data Security]] — encryption, access control, and secret handling that a bucket of plain-text state requires
- [[concepts/devops/trivy|Trivy]] — scans the bootstrap configuration for the bucket misconfigurations listed above

## References

- [Terraform S3 backend documentation](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Terraform state locking](https://developer.hashicorp.com/terraform/language/state/locking)
