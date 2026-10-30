---
title: Jaeger
tags: [devops, observers, jaeger, opentelemetry, overview]
created: 2026-10-30 11:09:32
updated: 2026-10-30 11:17:54
---

# Jaeger

Jaeger is an open-source distributed tracing platform. It collects, stores, and visualizes *traces*: records of how a single request moved through many services and how long each step took. It provides the tracing signal in [[concepts/devops/observers|Observers]] and is a CNCF graduated project, originally built at Uber.

> [!info] Scope of this note
> A tool overview covering the tracing model, Jaeger's components, sampling, and how it relates to OpenTelemetry. It is not a deployment guide.

## Why It Matters

In a monolith, a stack trace shows where time went. In a system of dozens of services, one slow checkout might be caused by a database call four hops away. Metrics show *that* latency rose, and logs on each service show fragments. A trace joins those fragments into one timeline, so you can see which hop was slow, which failed, and which ran in sequence when they could have run in parallel.

## The Tracing Model

| Term | Meaning |
| --- | --- |
| **Trace** | The full journey of one request, identified by a trace ID |
| **Span** | One timed operation within it (an HTTP handler, a DB query), with a name, start, duration, attributes, and events |
| **Parent/child** | Spans form a tree: a span's children are the calls it made |
| **Context propagation** | Passing the trace ID and parent span ID across process boundaries, normally in the W3C `traceparent` HTTP header or message headers |

> [!important] Propagation is the whole game
> A trace is only as complete as its least-instrumented hop. If one service, proxy, or queue consumer drops the `traceparent` header, the trace splits into disconnected pieces. Instrumenting every service, including asynchronous consumers, matters more than which backend you choose.

## Architecture

- **Instrumentation.** Applications use the **OpenTelemetry** SDKs and auto-instrumentation libraries. Jaeger's own client libraries are retired, and Jaeger accepts OTLP natively.
- **Collector.** Receives spans, validates them, applies sampling configuration, and writes to storage. Jaeger v2 is built on the OpenTelemetry Collector framework, so OTel processors such as tail sampling are available inside it.
- **Storage.** Pluggable: Cassandra, Elasticsearch, or OpenSearch for production (see [[concepts/devops/logging/elasticsearch|Elasticsearch]]), Badger or in-memory for development. [[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]] can sit between collector and storage as a buffer at high volume.
- **Query service and UI.** Search by service, operation, tags, and duration. The UI offers a timeline (Gantt) view per trace, trace comparison, and a service dependency graph derived from the spans.

## Sampling

Storing every span of every request is usually too expensive, so traces are sampled:

| Strategy | Decided | Trade-off |
| --- | --- | --- |
| **Head-based, probabilistic** | At the first span, e.g. keep 1% | Cheap and simple; the interesting slow or failed requests are mostly discarded |
| **Rate-limiting** | At the first span, N traces per second | Bounded cost per service regardless of traffic |
| **Remote / adaptive** | Collector pushes per-service, per-operation rates to the SDKs | Low-traffic endpoints stay visible beside high-traffic ones |
| **Tail-based** | After the whole trace is collected | Can keep *all* errors and slow traces; needs the spans of a trace buffered in one place |

## How to Think About It

The following is judgement, not documentation. Since the move to OpenTelemetry, *instrumentation* and *backend* are separate decisions. Instrument with OpenTelemetry regardless of backend, then choose Jaeger if you want a self-hosted, open-source trace store with a mature UI. Grafana Tempo is the usual alternative: it stores traces cheaply in object storage, keeps only a minimal index, and relies on Grafana for exploration. Zipkin is the older project that inspired Jaeger's data model.

Tracing pays off most when the trace ID also appears in every log line and in metric exemplars. Then a Prometheus latency alert leads to a trace, and the trace leads to the exact log lines for that request.

## Related Concepts

- [[concepts/devops/observers|Observers]] — where traces fit beside logs and metrics, and the correlation that makes all three useful
- [[concepts/devops/logging/elasticsearch|Elasticsearch]] — the most common production storage for Jaeger, and where trace-ID-tagged logs live
- [[concepts/devops/metrics/prometheus|Prometheus]] — metric exemplars point from a latency spike to a Jaeger trace
- [[concepts/data_engineering/kafka/apache_kafka|Apache Kafka]] — the buffer between collector and storage at high span volume, and a hop where context propagation through message headers is easy to lose
- [[concepts/software_architecture/software_architecture|Software Architecture]] — why trace context must cross every component boundary by design

## References

- [Jaeger documentation](https://www.jaegertracing.io/docs/) — architecture, deployment, sampling, storage backends
- [W3C Trace Context](https://www.w3.org/TR/trace-context/) — the `traceparent` propagation standard
- [OpenTelemetry](https://opentelemetry.io/) — the instrumentation SDKs Jaeger now relies on
