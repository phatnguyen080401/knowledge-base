---
title: Elasticsearch
tags: [devops, observers, elasticsearch, kibana, logstash, overview]
created: 2026-10-30 11:09:32
updated: 2026-10-30 11:17:54
---

# Elasticsearch

Elasticsearch is a distributed search and analytics engine built on Apache Lucene and developed by Elastic. It stores JSON documents, makes every field searchable through an inverted index, and spreads the data across a cluster of nodes. In an operations team its most common job is the log store in the ELK stack, the logging signal described in [[concepts/devops/observers|Observers]].

> [!info] Scope of this note
> This note covers Elasticsearch as a *logging backend*. It is also used for site search, security analytics (SIEM), and vector search, which this note mentions only in passing.

## Why It Matters

Logs carry the detail that metrics aggregate away, but raw log files spread across hundreds of hosts and containers are unsearchable in practice. Elasticsearch makes centrally collected logs queryable in seconds: full-text search, field filters, and aggregations ("count 5xx responses by service in the last hour") over billions of events. Kibana puts a UI on top for engineers who do not want to write queries.

## The Elastic Stack (ELK)

| Component | Role |
| --- | --- |
| **Beats / Elastic Agent** | Lightweight shippers on each host; Filebeat tails log files and container output |
| **Logstash** | Server-side pipeline that parses, enriches, and transforms events (grok patterns, GeoIP) before indexing |
| **Elasticsearch** | Stores, indexes, and searches the events |
| **Kibana** | Discover view for searching logs, dashboards, alerting, and stack management |

ELK originally stood for Elasticsearch, Logstash, Kibana; once Beats was added, Elastic renamed the set the Elastic Stack. Fluentd or Fluent Bit often replace Logstash and Beats (the "EFK" variant), especially on Kubernetes. Ingest pipelines inside Elasticsearch itself can now do much of the parsing Logstash used to do.

## How It Stores Data

- **Index.** A named collection of documents with a *mapping*, which is the schema giving each field's type (`keyword` for exact values, `text` for analysed full-text, `date`, numbers).
- **Shards and replicas.** Each index is split into primary shards, and each primary has replica copies on other nodes. Shards are the unit of distribution and recovery. Too many small shards waste heap memory, and too few large ones slow down recovery.
- **Inverted index.** Lucene maps each term to the documents that contain it, which is why search is fast and why indexing costs CPU and disk up front.
- **Near-real-time.** A document becomes searchable after the next *refresh*, by default about one second after indexing.

## Running It for Logs

- **Data streams and index templates.** Logs are append-only time series. A data stream writes to a hidden series of backing indices that roll over by size or age, and an index template sets their mappings and settings.
- **Index Lifecycle Management (ILM).** Moves indices through hot → warm → cold → frozen → delete phases. Each phase can shrink the index, reduce replicas, or move it to cheaper nodes. Retention is a policy setting, not a cron job.
- **Elastic Common Schema (ECS).** A shared field naming convention (`service.name`, `trace.id`, `log.level`). If every source uses it, one dashboard and one query work across all of them, and the `trace.id` field links a log line to its [[concepts/devops/tracing/jaeger|Jaeger]] trace.
- **Query languages.** KQL in Kibana's search bar, the JSON Query DSL over the REST API, and ES|QL, Elastic's newer piped query language.

> [!warning] Dynamic mapping explodes on unstructured fields
> By default, Elasticsearch adds a new mapped field the first time it sees one. Logs that put request IDs or user data into field *names* can create thousands of fields, which hits the field limit and slows the cluster. Define explicit mappings in the template, and log variable data as values, not keys.

## How to Think About It

The following is judgement, not documentation. Elasticsearch indexes *every field of every event*, so queries are flexible and fast. The price is storage and memory that grow with log volume. Two consequences follow:

- **Cost is the main design constraint.** Set retention per data stream, drop debug-level noise before it is indexed, and use ILM tiers. A cluster sized for "keep everything for a year" usually becomes the largest line on the infrastructure bill.
- **It is not the only design.** Grafana Loki indexes only a few labels and stores the log lines as compressed chunks, so it is much cheaper but slower for ad-hoc full-text search. Pick Elasticsearch when people really do search and aggregate across log *content*.

Licensing changed in 2021: Elastic moved Elasticsearch and Kibana from Apache 2.0 to a dual licence (Elastic License or SSPL). AWS responded by forking the last Apache-licensed version as **OpenSearch**. In 2024 Elastic added AGPLv3 as a further option. The two projects have diverged since the fork, so check which one a tool or managed service actually targets.

Elasticsearch also supports dense-vector fields and approximate nearest-neighbour search, which puts it in the "vector support in an existing database" category of [[concepts/databases/vector_database|Vector Database]].

## Related Concepts

- [[concepts/devops/observers|Observers]] — where logs fit beside metrics and traces, and how the three are correlated
- [[concepts/devops/tracing/jaeger|Jaeger]] — Elasticsearch and OpenSearch are Jaeger's most common production trace storage, and `trace.id` in logs links the two
- [[concepts/devops/metrics/prometheus|Prometheus]] — the metrics counterpart: cheaper aggregates that tell you *when* to go searching the logs
- [[concepts/databases/vector_database|Vector Database]] — the same engine used for semantic search rather than log search

## References

- [Elasticsearch documentation](https://www.elastic.co/docs) — data streams, ILM, mappings, ES|QL
- [Elastic Common Schema](https://www.elastic.co/docs/reference/ecs) — the shared field naming convention
- [OpenSearch](https://opensearch.org/) — the Apache-2.0 fork
