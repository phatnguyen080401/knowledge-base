---
title: API and Integration Protocols
tags: [data-architecture, api-protocols]
created: 2026-09-23 11:54:32
updated: 2026-09-23 13:16:00
---

# API and Integration Protocols

API and integration protocols are the agreed conventions — transport, message format, and interaction pattern — that let one system exchange data with another. The choice of protocol is an architectural decision that shapes latency, coupling, scalability, and operability, which is why it belongs to [[concepts/data_architecture|Data Architecture]] rather than to any single application.

## Why It Matters

- **Coupling:** A synchronous call binds the caller's availability to the callee's; an event on a broker does not.
- **Latency and freshness:** Polling a REST endpoint every five minutes and subscribing to a push stream produce very different data freshness.
- **Cost of change:** Protocols with rigid contracts (SOAP, EDI) are expensive to evolve; flexible ones (GraphQL) move that cost to governance and monitoring.
- **Operability:** Retries, ordering, deduplication, and back-pressure are either provided by the protocol or become your problem.
- **Governance surface:** Every integration is a place where [[concepts/data_security|Data Security]] controls.

## Three Interaction Styles

Almost every protocol below is a variation on one of three styles:

| Style | Who initiates | Coupling | Typical protocols |
| --- | --- | --- | --- |
| Request–response | Client, on demand | Tight (caller waits) | REST, GraphQL, gRPC, SOAP |
| Server push / streaming | Server, after a subscription | Medium | Webhooks, SSE, WebSockets, gRPC streaming |
| Message-brokered | Producer, asynchronously | Loose (broker in between) | MQTT, AMQP |

Pick the style first, then the protocol. Most integration mistakes are style mistakes, not protocol mistakes.

## Request–Response Protocols

### REST

REST (Representational State Transfer) is an architectural style over HTTP that models the domain as **resources** addressed by URLs and manipulated with standard verbs (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`). Responses are usually JSON, and HTTP status codes carry the outcome.

- **Strengths:** ubiquitous tooling, cacheable via HTTP semantics, stateless and easy to scale horizontally, low learning curve.
- **Weaknesses:** *over-fetching* (the endpoint returns more fields than you need) and *under-fetching* (one screen needs three round trips), no built-in schema, versioning is a manual discipline (`/v2/...`).
- **Use when:** you are exposing CRUD-shaped resources to many unknown consumers and want maximum interoperability.

### GraphQL

GraphQL is a query language and runtime for APIs. The server publishes a strongly typed **schema**; the client sends a query describing exactly the fields it wants, and receives a response with that exact shape. Typically a single `POST /graphql` endpoint serves everything.

- **Strengths:** eliminates over- and under-fetching, one round trip for nested data, introspectable schema, additive evolution instead of versioning.
- **Weaknesses:** HTTP caching no longer works out of the box, arbitrary client queries can be expensive (needs depth/complexity limits), authorization must be enforced per field, and per-endpoint rate limiting is meaningless.
- **Use when:** clients are diverse (mobile, web, partners) and their data needs vary and change faster than the backend.

### gRPC

gRPC is a high-performance **Remote Procedure Call** framework: you define services and messages in a `.proto` file, and the toolchain generates strongly typed client and server code in a dozen languages. Messages travel as binary **Protocol Buffers** over HTTP/2, so calls look like ordinary local function invocations to the developer.

- **Four call types:** unary (one request, one response), server streaming, client streaming, and bidirectional streaming — which is why gRPC appears in both the request–response and streaming rows above.
- **Strengths:** compact binary payloads and HTTP/2 multiplexing give it the best throughput and latency of the HTTP-family protocols; the `.proto` file is an enforced contract with generated stubs; first-class deadlines, cancellation, and streaming; field-number-based schema evolution keeps old and new clients compatible.
- **Weaknesses:** not human-readable on the wire (you need `grpcurl` or reflection to debug), no native browser support without a gRPC-Web proxy, HTTP caching and plain load balancers do not understand it, and the toolchain must be part of the build.
- **Use when:** internal service-to-service traffic in a microservice or polyglot estate, low-latency or high-volume internal calls, and streaming RPCs. Prefer REST or GraphQL at the public edge where reach matters more than speed.

### SOAP

SOAP (Simple Object Access Protocol) is an XML-based messaging protocol with a formal contract in **WSDL** and a family of WS-\* extensions (WS-Security, WS-ReliableMessaging, WS-AtomicTransaction). It is transport-agnostic but almost always runs over HTTP.

- **Strengths:** machine-readable contract enabling code generation, built-in standards for message-level signing/encryption and distributed transactions, strict validation.
- **Weaknesses:** verbose payloads, heavyweight tooling, poor fit for browsers and mobile.
- **Use when:** you integrate with banking, insurance, telecom, or government systems where the standard is mandated, or you genuinely need message-level security and formal transactions.

## Push and Streaming Protocols

### Webhooks

A webhook is a **reverse API call**: the consumer registers a callback URL, and the provider issues an HTTP `POST` to that URL when an event occurs. It is the simplest way to avoid polling.

- **Strengths:** trivial to implement on both sides, works with existing HTTP infrastructure, near-real-time.
- **Weaknesses:** the receiver must be publicly reachable and highly available; delivery is at-least-once at best, so receivers must be **idempotent**; ordering is not guaranteed; failures need retries with exponential backoff and a dead-letter path.
- **Security essentials:** verify an HMAC signature on every payload, validate timestamps to block replay, and allowlist source IP ranges. Never trust webhook body contents without verification.

### Server-Sent Events (SSE)

SSE is a **one-way, server-to-client** stream over a single long-lived HTTP response with content type `text/event-stream`. The browser's `EventSource` API reconnects automatically and resumes via a `Last-Event-ID` header.

- **Strengths:** plain HTTP (proxies, auth, and compression just work), automatic reconnection, very simple server implementation.
- **Weaknesses:** text only, server-to-client only, and connection limits per browser/domain on HTTP/1.1.
- **Use when:** live dashboards, notification feeds, progress indicators, or streaming LLM responses — anything where the client only ever listens.

### WebSockets

WebSockets upgrade an HTTP connection into a persistent, **full-duplex**, bidirectional channel (`ws://` / `wss://`) carrying text or binary frames with minimal per-message overhead.

- **Strengths:** lowest latency for two-way traffic, efficient for high message rates, binary-capable.
- **Weaknesses:** stateful connections complicate load balancing and horizontal scaling, no built-in reconnection or message semantics, authentication must be handled at the handshake, and some corporate proxies interfere.
- **Use when:** chat, collaborative editing, multiplayer state, or trading screens — cases where the client also sends frequently.

> [!tip] SSE or WebSockets?
> If the client never needs to push, choose SSE. Reaching for WebSockets "just in case" buys you the operational cost of stateful connections for no benefit.

## Message-Brokered Protocols

### MQTT

MQTT (Message Queuing Telemetry Transport) is a lightweight **publish/subscribe** protocol built for constrained devices and unreliable networks. Clients publish to hierarchical **topics** (`factory/line3/sensor7/temp`) on a broker; subscribers use wildcards (`+` single level, `#` multi-level).

- **Quality of Service:** QoS 0 (at most once), QoS 1 (at least once, duplicates possible), QoS 2 (exactly once, most expensive).
- **Other features:** retained messages give new subscribers the last known value, *Last Will and Testament* announces unexpected disconnects, and headers are only a couple of bytes.
- **Use when:** IoT telemetry, connected vehicles, and sensor fleets on low-bandwidth or intermittent links.

### AMQP

AMQP (Advanced Message Queuing Protocol) is a full enterprise messaging protocol. In the widely deployed 0-9-1 model, producers publish to an **exchange**, which routes to **queues** by binding rules (direct, topic, fanout, headers), and consumers read from queues with explicit acknowledgements.

- **Strengths:** rich routing, durable queues, transactions, per-message acknowledgement and redelivery, flow control, dead-letter queues.
- **Weaknesses:** heavier than MQTT, and the broker becomes critical infrastructure to operate and secure.
- **Use when:** reliable inter-service work distribution, task queues, and order-processing style workflows inside an enterprise.

## Event-Driven Architecture (EDA)

EDA is not a protocol but an **architectural style** in which services communicate by emitting and reacting to immutable *events* — factual records of something that already happened (`OrderPlaced`, `MeterReadingRecorded`). Producers do not know their consumers.

- **Building blocks:** event producers, an event broker or log (AMQP brokers, MQTT brokers, log-based platforms), and independent consumers.
- **Patterns:** event notification (thin event, consumer calls back for detail), event-carried state transfer (fat event, no callback needed), event sourcing (the event log *is* the system of record), and CQRS.
- **Benefits:** loose coupling, independent scaling and deployment, natural fan-out to analytics, and a replayable audit trail.
- **Costs:** eventual consistency, harder debugging and end-to-end tracing, duplicate and out-of-order delivery to design around, and schema governance becomes essential — event schemas belong in the catalog described by [[concepts/metadata_management|Metadata Management]].

## Electronic Data Interchange (EDI)

EDI is the decades-old standard for exchanging **structured business documents** — purchase orders, invoices, shipping notices, healthcare claims — directly between organizations in a fixed, machine-readable format.

- **Standards:** ANSI X12 (predominantly North America) and UN/EDIFACT (international); common transaction sets include 850 (purchase order), 810 (invoice), and 856 (advance ship notice).
- **Transports:** AS2 over HTTPS, SFTP, or a VAN (Value-Added Network).
- **Character:** rigid positional or delimited segments, trading-partner agreements that specify every field, and mandatory acknowledgements (997/CONTRL).
- **Use when:** you have no choice — retail, logistics, healthcare, and automotive supply chains still run on it. EDI is usually translated into JSON or a warehouse schema at the edge, and its trading-partner identifiers are a classic source of [[concepts/master_data_management|Master Data Management (MDM)]] work.

## Comparison at a Glance

| Protocol | Direction | Transport | Payload | Delivery guarantee | Typical use |
| --- | --- | --- | --- | --- | --- |
| REST | Request–response | HTTP | JSON | None (retry is the caller's job) | Public and internal CRUD APIs |
| GraphQL | Request–response | HTTP | JSON | None | Client-shaped queries across varied consumers |
| gRPC | Request–response and streaming | HTTP/2 | Protocol Buffers (binary) | None (deadlines, retries, and idempotency are the caller's job) | Internal service-to-service and polyglot microservices |
| SOAP | Request–response | HTTP, JMS, SMTP | XML | WS-ReliableMessaging (optional) | Regulated enterprise integration |
| Webhooks | Server → client | HTTP | JSON | At-least-once, provider-dependent | SaaS event notifications |
| SSE | Server → client | HTTP | Text | Resume via `Last-Event-ID` | Live feeds, dashboards, token streams |
| WebSockets | Bidirectional | TCP (HTTP upgrade) | Text or binary | None (application's job) | Chat, collaboration, live trading |
| MQTT | Pub/sub | TCP, WebSocket | Binary | QoS 0 / 1 / 2 | IoT and telemetry |
| AMQP | Pub/sub, queueing | TCP | Binary | Acknowledged, durable | Enterprise messaging and task queues |
| EDI | Document exchange | AS2, SFTP, VAN | X12, EDIFACT | Functional acknowledgement | B2B trading-partner documents |

## Choosing a Protocol

1. **Does the consumer need data on demand, or when something happens?** On demand → request–response. On an event → push or broker.
2. **Is there exactly one consumer, or many unknown ones?** Many → put a broker or event log between them.
3. **How bad is a lost message?** Tolerable → REST or webhooks with retries. Unacceptable → AMQP or MQTT QoS 1+ with durable storage and idempotent consumers.
4. **How constrained is the network or device?** Severely → MQTT.
5. **Who is the consumer — your own services or the outside world?** Internal and performance-sensitive → gRPC. Public, browser-facing, or partner-facing → REST or GraphQL.
6. **Does an external standard already dictate the answer?** Partner mandates SOAP or EDI → that discussion is over.
7. **Who owns the contract?** Whatever you choose, the schema is a governed asset: version it, publish it, and monitor breaking changes.

## Governance and Security Considerations

- **Authentication and authorization** at every entry point — OAuth 2.0 / OIDC for HTTP APIs, mTLS or SAS tokens for brokers. See [[concepts/data_security|Data Security]].
- **Transport encryption** everywhere (`https://`, `wss://`, `mqtts://`, AS2 over TLS); message-level encryption where intermediaries must not read payloads.
- **Rate limiting and quotas**, including query-complexity limits for GraphQL, which plain request-count limits cannot cover.
- **Schema and contract registry** so producers cannot break consumers silently; treat API and event schemas as catalogued metadata.
- **Validation at the boundary.** Contracts constrain structure, not truth — apply [[concepts/data_quality|Data Quality]] rules to inbound payloads.
- **Idempotency and replay protection** for anything delivered at-least-once: webhooks, MQTT QoS 1, AMQP redelivery.
- **Auditability.** Log every exchange with a correlation ID so lineage across systems remains traceable.

## Related Concepts

- [[concepts/data_architecture|Data Architecture]] — integration protocols are one of the structural choices architecture governs
- [[concepts/data_security|Data Security]] — every API and broker is an access point that must be authenticated, encrypted, and rate limited
- [[concepts/metadata_management|Metadata Management]] — API and event schemas are governed metadata that belong in the catalog
- [[concepts/master_data_management|Master Data Management (MDM)]] — cross-system integration is where identifier mismatches surface and golden records are reconciled
- [[concepts/data_governance|Data Governance]] — sets the policy for who may expose or consume which data over which interface
