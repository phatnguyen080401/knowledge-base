---
title: Observers
tags: [devops, observers, overview]
created: 2026-10-30 11:09:32
updated: 2026-10-30 11:17:54
---

# Observers

Observers are the tools that watch software while it runs and record what it did. Engineers use them to tell whether a system is healthy and to explain, after the fact, why it behaved the way it did. The usual name for this property is *observability*. [[concepts/software_architecture/software_architecture|Software Architecture]] lists observability as a quality attribute that has to be designed in. This hub covers the telemetry behind it and the tool this vault files for each kind.

> [!info] Scope of this note
> This hub routes to one tool note per signal. Each tool note says what the tool is for and where it fits. None of them is a configuration reference. Everything here is general industry knowledge, not taken from a single source.

## Why It Matters

Monitoring answers questions you thought to ask in advance: is the error rate above 1%? Observability is the wider goal of being able to answer questions you did *not* anticipate from the data the system already emits: why are requests from one tenant slow only on Tuesdays? A system that emits only aggregate metrics can say that something is wrong but rarely why. A system that emits only logs can say why, but only once you know where to look. Each kind of signal covers a gap in the others.

## The Three Signals

| Signal | What it records | Strength | Weakness | Tool in this vault |
| --- | --- | --- | --- | --- |
| **Logs** | Discrete, timestamped events, ideally structured (JSON) | Full detail about one event | Expensive to store and index at volume; no built-in causal link between services | [[concepts/devops/logging/elasticsearch\|Elasticsearch]] |
| **Metrics** | Numeric measurements aggregated over time, identified by name and labels | Cheap, fast to query, ideal for dashboards and alerting | Aggregation discards the individual event; high-cardinality labels break storage | [[concepts/devops/metrics/prometheus\|Prometheus]] |
| **Traces** | The path of one request across services, as a tree of timed spans | Shows where time went and which hop failed | Usually sampled; needs every service to propagate context | [[concepts/devops/tracing/jaeger\|Jaeger]] |

Profiles (continuous CPU and memory profiling) are increasingly treated as a fourth signal, but this vault has no note on them yet.

## Correlating Signals

Each signal is far more useful when you can jump from it to the others:

- **Trace ID in every log line.** If the logging library writes the active trace and span IDs into each structured log, one slow trace leads straight to the log lines for that exact request.
- **Exemplars.** A metric sample can carry the trace ID of one request it counted. A latency spike on a dashboard then links to a real trace that caused it.
- **Shared resource labels.** Use the same `service`, `environment`, and `version` labels on every signal so that filters work across all three.

[OpenTelemetry](https://opentelemetry.io/) is the CNCF standard for producing all three signals: vendor-neutral APIs, SDKs, a wire protocol (OTLP), and the Collector. Instrumenting with it separates *how the data is produced* from *which backend stores it*. That is why each tool note below says how the tool accepts OpenTelemetry data.

## What to Measure

Two widely used checklists decide which metrics deserve a dashboard and an alert:

- **Four golden signals** (Google SRE book): latency, traffic, errors, and saturation, for each user-facing service.
- **RED** (rate, errors, duration) for request-driven services, and **USE** (utilization, saturation, errors) for resources such as CPU, disks, and queues.

> [!tip] Alert on symptoms, investigate with causes
> Page a human on what users feel (error rate, latency against an SLO). Keep cause-level signals, such as CPU or a single pod restart, on dashboards and in tickets. Otherwise alert fatigue sets in quickly.

## Choosing a Stack

These three tools are not the only open-source option for each signal. A common alternative keeps all three signals in one vendor's family:

| Signal | Tool in this vault | Common alternatives |
| --- | --- | --- |
| Logs | Elasticsearch (ELK / Elastic Stack) | OpenSearch, Grafana Loki, Splunk |
| Metrics | Prometheus | Grafana Mimir, Thanos, VictoriaMetrics (all Prometheus-compatible) |
| Traces | Jaeger | Grafana Tempo, Zipkin |
| Dashboards | Kibana (logs), Grafana (metrics, traces) | Grafana for everything |

## Related Concepts

- [[concepts/devops/logging/elasticsearch|Elasticsearch]] — the log store: indexing, retention, and search over structured events
- [[concepts/devops/metrics/prometheus|Prometheus]] — the metrics system: scraping, PromQL, and alerting
- [[concepts/devops/tracing/jaeger|Jaeger]] — the tracing backend: spans, sampling, and following a request across services
- [[concepts/software_architecture/software_architecture|Software Architecture]] — why correlation IDs and traces must cross component boundaries by design, not be added afterwards
- [[concepts/devops/trivy|Trivy]] — the other half of running software safely: build-time scanning, where observers handle runtime behaviour

## References

- [OpenTelemetry](https://opentelemetry.io/) — the vendor-neutral instrumentation standard and OTLP
- [Google SRE Book — Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) — the four golden signals
