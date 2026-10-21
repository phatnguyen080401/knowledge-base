---
title: FIX Protocol (Financial Information eXchange)
tags: [software-architecture, api-protocols, compatibility-contracts, fix-protocol]
created: 2026-10-20 15:08:33
updated: 2026-10-21 14:23:04
---

# FIX Protocol (Financial Information eXchange)

FIX is the open, vendor-neutral messaging standard that capital-markets participants use to exchange orders, executions, quotes, and market data electronically. It is a domain-mandated member of the family described in [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]]: like EDI in retail and logistics, you do not choose FIX on technical merit — you adopt it because every counterparty already speaks it.

## Why It Matters

- **It is the trading industry's lingua franca.** Buy-side firms, sell-side brokers, exchanges, and execution venues connect to each other over FIX sessions; a new venue that spoke anything else would have no counterparties.
- **It is a primary data source, not just a pipe.** FIX logs and drop-copy sessions are the raw record behind transaction cost analysis, best-execution reporting, trade surveillance, and regulatory reporting. Much of the work of a capital-markets data platform is parsing FIX into analyzable tables.
- **It is session-stateful.** Unlike REST, a FIX connection carries sequence numbers, gap recovery, and heartbeats. Treating it as stateless request–response is the single most common integration mistake.
- **"FIX-compliant" means very little on its own.** Every counterparty publishes a *rules of engagement* document narrowing the standard to a dialect, so two certified FIX engines still need a bilateral certification before they can trade.

## Origin and Governance

FIX began in 1992 as a bilateral protocol between Fidelity Investments and Salomon Brothers for equity order flow, replacing phone calls and faxes. It was published openly rather than licensed, and is now maintained by the **FIX Trading Community** (formerly FIX Protocol Ltd.), a non-profit, member-driven body. The specification is free to implement, which is a large part of why it spread beyond equities into fixed income, foreign exchange, listed derivatives, and post-trade processing.

## Two Layers

FIX is best understood as two protocols stacked on one connection:

| Layer | Responsibility | Messages |
| --- | --- | --- |
| **Session** | Establish the connection, authenticate, sequence, detect loss, recover gaps, tear down | Logon, Logout, Heartbeat, Test Request, Resend Request, Sequence Reset, Reject |
| **Application** | Convey business intent — orders, executions, quotes, allocations, market data | New Order Single, Execution Report, Cancel/Replace, Market Data Request, Trade Capture Report |

Up to FIX 4.4 the two layers were versioned together. From FIX 5.0 they were split: **FIXT.1.1** defines the session layer, and the application version is negotiated independently via `DefaultApplVerID` (1137). That split is what allows a venue to add new business messages without forcing every counterparty to renegotiate transport behaviour.

## Message Structure

The classic encoding is **tag=value**: a flat sequence of `<tag>=<value>` pairs, each terminated by the non-printable `SOH` character (ASCII `0x01`). Rendered with `|` standing in for `SOH`, a new order looks like:

```text
8=FIX.4.4|9=145|35=D|49=BUYSIDE|56=BROKER|34=1215|52=20261020-13:45:02.317|
11=ORD-00093|55=AAPL|54=1|38=500|40=2|44=182.75|59=0|60=20261020-13:45:02.310|10=094|
```

Three parts are mandatory and ordered:

- **Header** — `BeginString` (8) names the version, `BodyLength` (9) counts the bytes between it and the checksum, `MsgType` (35) identifies the message, `SenderCompID` (49) / `TargetCompID` (56) identify the parties, `MsgSeqNum` (34) orders the stream, `SendingTime` (52) is a UTC timestamp.
- **Body** — the message-specific fields.
- **Trailer** — `CheckSum` (10), the sum of every preceding byte modulo 256, zero-padded to three digits. It is a corruption check only; it provides no authentication.

Fields are identified by number, not name, so the wire format is compact but unreadable without a data dictionary. Tags **5000–9999** are reserved for user-defined fields, which is how venues bolt on proprietary attributes — and how dialects proliferate.

### Repeating Groups

Lists are expressed as a count field followed by repeated blocks, for example `NoPartyIDs` (453) followed by one `PartyID`/`PartyIDSource`/`PartyRole` triplet per party. The first field of each repetition is a required delimiter that marks the boundary; a parser that ignores delimiter rules will silently mis-associate fields in nested groups. Repeating groups are the hardest part of FIX parsing and the usual source of interoperability bugs.

## Session Mechanics

1. **Logon (`35=A`)** — the initiator sends `HeartBtInt` (108) proposing a heartbeat interval; the acceptor echoes it. Optional `Username` (553) / `Password` (554) carry credentials, and `ResetSeqNumFlag` (141) requests a fresh sequence.
2. **Sequence numbers** — strictly increasing by one per direction, per session. They are the delivery guarantee: a receiver that sees a gap must not process the message.
3. **Gap recovery** — on a gap the receiver sends a **Resend Request** (`35=2`); the sender replays the missing range, marking already-superseded administrative messages with a **Sequence Reset** (`35=4`) in gap-fill mode. Replayed application messages carry `PossDupFlag` (43) so the receiver can deduplicate.
4. **Liveness** — if nothing has been sent for `HeartBtInt`, send a **Heartbeat** (`35=0`). If nothing has been *received*, send a **Test Request** (`35=1`); silence after that means the session is dead and gets disconnected.
5. **Reset cadence** — most venues reset sequence numbers at a daily session boundary; some run weekly or continuous sessions. Mismatched expectations here cause the classic "cannot log on Monday morning" incident.

> [!warning] Sequence state is durable state
> A FIX engine must persist outbound messages and both sequence counters to disk. After a crash it has to resume from the stored sequence and be able to replay anything the counterparty did not acknowledge. An engine that keeps session state only in memory will lose orders.

## The Order Lifecycle

The application layer is dominated by one exchange: **New Order Single** (`35=D`) out, a stream of **Execution Reports** (`35=8`) back.

| Message | Type | Purpose |
| --- | --- | --- |
| New Order Single | `D` | Submit an order: `ClOrdID` (11), `Symbol` (55), `Side` (54), `OrderQty` (38), `OrdType` (40), `Price` (44), `TimeInForce` (59) |
| Execution Report | `8` | Every state change: acknowledgement, partial fill, fill, cancel, expiry, reject |
| Order Cancel Request | `F` | Cancel a live order, referencing `OrigClOrdID` (41) |
| Order Cancel/Replace Request | `G` | Amend price or quantity, also chaining through `OrigClOrdID` |
| Order Cancel Reject | `9` | The cancel or amend could not be applied |
| Market Data Request / Snapshot / Incremental Refresh | `V` / `W` / `X` | Subscribe to and receive quote and depth updates |
| Trade Capture Report | `AE` | Post-trade confirmation and matching |

Two conventions govern reading this stream:

- **`ClOrdID` is unique per request, not per order.** Each cancel or replace mints a new `ClOrdID` and points at the previous one via `OrigClOrdID`, forming a chain. Reconstructing "the order" from logs means walking that chain, not grouping by a single identifier.
- **`ExecType` (150) and `OrdStatus` (39) answer different questions.** `ExecType` describes *this event*; `OrdStatus` describes the order's state *after* it. Analytics that conflate them will double-count fills. The authoritative running totals are `CumQty` (14), `LeavesQty` (151), and `AvgPx` (6).

A **drop copy** session is a read-only feed of the same Execution Reports sent to a third destination — risk, operations, or the data platform — so downstream consumers never contend with the trading path.

## Versions and Encodings

**Versions.** 4.2 and 4.4 remain the most widely deployed; 4.4 is the common default for new equity connectivity. 5.0 and its service packs (SP1, SP2) introduced the FIXT session split. Since 5.0 SP2 the standard evolves continuously through **Extension Packs**, cumulatively published as **FIX Latest**, rather than through big-bang version releases.

**Encodings.** Tag=value is the original and still the most common, but it is not the only one:

| Encoding | Form | Used for |
| --- | --- | --- |
| Tag=value | ASCII `tag=value` + `SOH` | General order flow; the default |
| FIXML | XML | Post-trade, clearing, and regulatory messaging |
| FAST | Compressed field encoding | High-volume market data feeds |
| SBE (Simple Binary Encoding) | Fixed-layout binary | Low-latency trading where parsing cost matters |
| JSON | Standard JSON | Web and REST-adjacent tooling |

Related specifications fill the remaining gaps: **FIXP** provides a lightweight binary session layer for use with SBE, and **FIX Orchestra** publishes rules of engagement in a machine-readable form so a counterparty's dialect can be code-generated instead of read out of a PDF.

## Transport and Security

FIX runs over a long-lived TCP connection, typically across a leased line, VPN, extranet, or exchange cross-connect. The protocol itself defines no encryption and only weak authentication — `SenderCompID`/`TargetCompID` are identifiers, not credentials, and the checksum detects corruption rather than tampering. Securing a FIX link therefore means:

- **TLS** on the connection (natively in the engine, or via a tunnel), which the FIX Trading Community now recommends as standard practice.
- **Network-level control** — IP allowlisting and private connectivity, since sessions are long-lived and well-known.
- **CompID and credential management** treated as access control, with per-session entitlements limiting what each counterparty may trade. See [[concepts/data_governance/data_security|Data Security]].
- **Immutable session logs**, which double as the audit trail regulators expect.

## Strengths and Weaknesses

- **Strengths:** universal adoption in capital markets, open and free to implement, mature engines in every language, built-in delivery guarantees via sequencing and gap fill, and extensibility through user-defined fields.
- **Weaknesses:** verbose and unreadable on the wire; ASCII parsing is costly at latency-sensitive speeds; no native security; the permissiveness that enables dialects also destroys plug-and-play interoperability; and optionality in the spec means "valid FIX" and "accepted by this venue" are different things.

The latency weakness is why exchanges often expose a proprietary binary protocol for order entry and market data alongside FIX, reserving FIX for broader connectivity. The dialect weakness is why onboarding a counterparty is a certification project, not a configuration change.

## FIX as a Data Source

For a data platform, FIX is an ingestion problem with sharp edges:

- **Parse with a dictionary, not with string splitting.** The meaning of a tag depends on the FIX version, the message type, and the counterparty's extensions, so the dictionary is governed metadata that belongs in the catalog — see [[concepts/data_governance/metadata_management|Metadata Management]].
- **Model the event stream, not the current state.** Execution Reports are an immutable event log; derive order state from them rather than overwriting rows, and keep the raw message for audit.
- **Expect duplicates and out-of-order delivery after recovery.** `PossDupFlag` (43) and `PossResend` (97) exist precisely because replay happens; consumers must be idempotent.
- **Timestamps are UTC and precision matters.** `SendingTime` (52) and `TransactTime` (60) are UTC; regulations such as MiFID II impose clock-synchronization and granularity requirements, so truncating sub-second precision during ingestion destroys compliance evidence.
- **Identifiers need reconciliation.** Instrument symbology (`Symbol`, `SecurityID` with `SecurityIDSource`), counterparty CompIDs, and `PartyID` roles vary per venue and must be mapped to internal identifiers — classic [[concepts/data_governance/master_data_management|Master Data Management (MDM)]] work.
- **Validate at the boundary.** A structurally valid message can still carry an economically impossible price or quantity; apply [[concepts/data_governance/data_quality|Data Quality]] rules on ingest.

## Related Concepts

- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — FIX is the capital-markets entry in the broader protocol landscape, and shares EDI's character as a mandated industry standard
- [[concepts/software_architecture/software_architecture|Software Architecture]] — FIX is what an interface decision looks like thirty years on: dialects, session state, and a contract nobody can unilaterally change
- [[concepts/data_governance/data_security|Data Security]] — FIX provides no encryption or real authentication of its own, so sessions must be secured at the transport and network layers
- [[concepts/data_governance/metadata_management|Metadata Management]] — FIX data dictionaries and counterparty rules of engagement are governed metadata without which messages cannot be interpreted
- [[concepts/data_governance/master_data_management|Master Data Management (MDM)]] — instrument symbology and counterparty identifiers must be reconciled across venues
- [[concepts/data_governance/data_quality|Data Quality]] — protocol conformance guarantees structure, not economic plausibility

## References

- [FIX Trading Community](https://www.fixtrading.org/) — the standard, extension packs, and FIX Latest
- [FIX Orchestra](https://www.fixtrading.org/standards/fix-orchestra/) — machine-readable rules of engagement
