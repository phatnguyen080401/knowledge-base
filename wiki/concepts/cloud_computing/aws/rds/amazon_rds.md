---
title: Amazon RDS (Relational Database Service)
tags: [cloud-computing, cost-management, aws, rds, stub]
created: 2026-10-31 11:27:30
updated: 2026-10-31 11:34:33
---

# Amazon RDS (Relational Database Service)

Amazon RDS is AWS's managed relational database service. It runs engines such as PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server, and AWS handles provisioning, patching, backups, and failover.

## Stopping an Instance

- An RDS DB instance can be stopped for a **maximum of 7 consecutive days**. After 7 days, RDS starts it again automatically.
- While the instance is stopped, instance hours are not billed, but storage and backups still are.
- This differs from [[concepts/cloud_computing/aws/ec2/amazon_ec2|Amazon EC2]], where a stopped instance stays stopped until someone starts it.

## Related Concepts

- [[concepts/cloud_computing/aws/ec2/amazon_ec2|Amazon EC2 (Elastic Compute Cloud)]] — the compute service whose instances can stay stopped indefinitely, and whose Savings Plans are the other main AWS cost lever
- [[concepts/devops/infrastructure_as_code/terraform|Terraform]] — the usual way RDS instances are provisioned and kept consistent across environments
