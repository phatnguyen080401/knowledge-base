---
title: Idempotency
tags: [software-architecture, api-protocols, distributed-systems, fault-tolerance, stub]
created: 2026-10-26 23:17:48
updated: 2026-10-31 10:43:45
---

# Idempotency

Idempotency is the property of an operation that produces the same result whether it is applied
once or many times, so a client can safely retry it after a timeout or failure without causing
duplicate side effects. It is what makes at-least-once delivery tolerable in
[[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] and in
data pipelines.

## Related Concepts

- [[concepts/software_architecture/exactly_once_delivery_and_processing|Exactly-Once Delivery and Processing]] — why exactly-once delivery is impossible, and how idempotency, deduplication, and outboxes give effectively-once processing instead
- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — HTTP method semantics and idempotency keys decide which calls are safe to retry
- [[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]] — its idempotent producer deduplicates retried sends, and its at-least-once and exactly-once semantics push idempotency onto consumers and external sinks
- [[concepts/data_engineering/workflow_orchestration|Workflow Orchestration]] — orchestrators retry failed tasks, so every task they run must be idempotent
- [[concepts/databases/distributed_consensus|Distributed Consensus]] — another answer to unreliable networks: agree on one outcome rather than make repeats harmless
