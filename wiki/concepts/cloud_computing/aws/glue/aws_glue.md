---
title: AWS Glue
tags: [cloud-computing, elt, aws, glue, stub]
created: 2026-10-31 11:27:30
updated: 2026-10-31 11:27:30
---

# AWS Glue

AWS Glue is AWS's serverless data integration service. It combines a Data Catalog of table metadata, crawlers that discover schemas, and ETL jobs that run on [[concepts/data_engineering/spark/apache_spark|Apache Spark]] without a cluster to manage.

## Job Bookmarks

- A **job bookmark** tracks the data a job has already processed, so that later runs do not reprocess old data.
- With job bookmarks enabled, Glue keeps track of the processed data and automatically resumes processing from where it left off in the next job run.
- Bookmarks are set per job with the `--job-bookmark-option` argument: `job-bookmark-enable`, `job-bookmark-disable`, or `job-bookmark-pause`.

## Related Concepts

- [[concepts/data_engineering/spark/apache_spark|Apache Spark]] — the engine Glue ETL jobs run on
- [[concepts/software_architecture/exactly_once_delivery_and_processing|Exactly-Once Delivery and Processing]] — the general problem of processing each input once across runs and failures, which bookmarks address for batch jobs
