---
title: Amazon EC2 (Elastic Compute Cloud)
tags: [cloud-computing, cost-management, aws, ec2, stub]
created: 2026-10-31 11:27:30
updated: 2026-10-31 11:34:33
---

# Amazon EC2 (Elastic Compute Cloud)

Amazon EC2 provides virtual servers, called instances, in the AWS cloud. They are billed On-Demand by usage, with discounts available in exchange for a usage commitment.

## Savings Plans

A Savings Plan commits to a consistent amount of compute usage, measured in dollars per hour, for a one- or three-year term, in exchange for rates below On-Demand.

| Plan | Savings off On-Demand | Applies to | Does not apply to |
| --- | --- | --- | --- |
| **EC2 Instance Savings Plans** | Up to 72% | One EC2 instance family in one chosen Region, regardless of size, OS, or tenancy within that family and Region | Other instance families or Regions; Fargate tasks and pods; Lambda functions |
| **Compute Savings Plans** | Up to 66% | EC2 usage across any instance family, size, Region, OS, or tenancy, as well as Fargate and Lambda | — |

The trade-off is discount against flexibility. EC2 Instance Savings Plans give the larger discount but lock the commitment to one family and Region. Compute Savings Plans give up some of the discount so that the commitment still applies after a workload changes family or Region, or moves to containers or serverless.

## Related Concepts

- [[concepts/cloud_computing/aws/rds/amazon_rds|Amazon RDS (Relational Database Service)]] — the managed database service, whose stop-and-auto-restart rule is a separate AWS cost lever
- [[concepts/devops/infrastructure_as_code/terraform|Terraform]] — the usual way EC2 instances and the networks around them are provisioned
