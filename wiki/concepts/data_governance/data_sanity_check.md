---
title: Data Sanity Check
tags: [data-governance, data-quality, data-validation, sanity-check]
created: 2026-10-22 13:14:46
updated: 2026-10-22 13:43:11
---

# Data Sanity Check

A data sanity check is a small, cheap, broad assertion run at a pipeline boundary to confirm that a dataset is *plausible* before anyone spends effort on it — the row count is in the right order of magnitude, the key is unique, the latest partition exists, the totals reconcile. It is the coarse first filter of [[concepts/data_governance/data_quality|Data Quality]]: it does not prove the data is correct, it proves the data is not obviously broken.

## Why It Matters

The value of a sanity check comes from *where* it sits, not from how clever it is.

- **It fails early, where the cause is still visible.** A load that silently wrote zero rows is trivial to diagnose at the ingestion boundary and nearly impossible to diagnose three transformation layers later, when it presents as a dashboard quietly reading low.
- **It stops bad data from propagating.** Without a boundary check, a defect fans out across every downstream model, extract, and report, and remediation becomes a backfill rather than a rerun.
- **It is cheap enough to always be on.** A count, a max timestamp, and a key-uniqueness test cost a fraction of the transformation they guard, so there is no trade-off to argue about — unlike full row-level validation, which has to be rationed.
- **It catches the failures that have no error.** Pipelines that crash are the easy case; the dangerous case is a job that exits zero having produced an empty, stale, or duplicated table.

## Sanity Check vs. Full Validation

Both are [[concepts/data_governance/data_quality|data quality]] checks and the vocabulary is used loosely, but they answer different questions and are tuned differently.

|               | Sanity check                                      | Full validation                        |
| ------------- | ------------------------------------------------- | -------------------------------------- |
| Question      | "Is this dataset plausible at all?"               | "Is every record correct?"             |
| Scope         | Aggregate — counts, extremes, totals              | Row-level and field-level              |
| Cost          | Negligible; metadata or a single scan             | Proportional to the data               |
| Frequency     | Every run, every boundary                         | Scheduled, sampled, or on change       |
| Tuned for     | Few false alarms; must be trusted enough to block | Coverage; expected to produce findings |
| Failure means | Something is structurally wrong — stop            | Some records are wrong — triage        |

The practical rule: a sanity check should almost never fire, and when it does, the pipeline is broken. A validation suite is *expected* to surface defects and feeds the measure-and-remediate loop instead of halting it.

## How a Check Works

Every sanity check, regardless of tool, is the same six-part structure. Tools differ only in which parts they make you write and which they infer.

| Part | What it is | Example |
| --- | --- | --- |
| **Subject** | The exact slice under test — table, partition, column | `marts.fct_orders`, partition `2026-10-22` |
| **Measurement** | One scalar the engine can compute cheaply | `COUNT(*)` = `48,214` |
| **Expectation** | The reference value to compare against | trailing same-weekday median = `47,900` |
| **Comparator + tolerance** | How close counts as equal | relative deviation, ±20% |
| **Verdict** | `pass` / `warn` / `fail` | `pass` (+0.7%) |
| **Action** | What happens on a non-pass | `fail` → abort before publish; `warn` → notify owner |

The comparison itself is trivial. The design work is entirely in the **subject** (checking the wrong slice is the most common silent bug) and the **expectation**.

### Where the expectation comes from

This is what separates a useful check from a decorative one, and there are only three answers.

| Source | How it is obtained | Strength | Weakness |
| --- | --- | --- | --- |
| **Static** | A human writes a constant from domain knowledge — `age BETWEEN 0 AND 120`, `status IN (…)` | Unambiguous; needs no state | Goes stale silently; only encodes what someone thought to write down |
| **Historical baseline** | Computed from past values of the same measurement — trailing median, mean ± n·σ | Self-updating; survives growth and seasonality | Learns a slow-moving defect as the new normal; needs a results table and a warm-up period |
| **Independent source** | Compared against a system outside the pipeline — source control totals, the system of record | The only kind that catches an error the pipeline makes *consistently* | Costs access and coordination with another team's system |

A mature suite uses all three: static rules for things that are definitionally true, baselines for volume and distribution, and one reconciliation against the system of record as the backstop.

### Stateless vs. stateful checks

A **stateless** check — uniqueness, not-null, range — needs nothing but the data in front of it. A **stateful** check — volume deviation, freshness trend, distribution drift — needs a record of what previous runs measured, which means the suite has to persist its own results:

```text
check_results
  run_id          — the orchestrator run that produced this row
  check_name      — stable identifier, never renamed
  subject         — table and partition under test
  measured_value  — the scalar
  expected_value  — the reference it was compared against
  verdict         — pass | warn | fail
  checked_at      — timestamp
```

That one table does triple duty: it is the baseline source for stateful checks, the evidence for whether a threshold is tuned correctly, and the measurement the quality lifecycle's *monitor* stage reports on. Without it, every check is stateless by default and the suite can only assert absolutes.

> [!tip] Exclude known-bad runs from the baseline.
> If a failed run's measurement is written to `check_results` and then feeds tomorrow's median, the baseline absorbs the incident and the check gets quieter each time it fires. Compute baselines from rows with `verdict = 'pass'` only.

### The cost ladder

"Cheap" is not a vague aspiration — it is a specific choice about how much data the check reads. Climb this ladder only as far as the check actually requires.

| Rung | Mechanism | Cost |
| --- | --- | --- |
| 1 | Catalog metadata — row count, last-modified time from the information schema | No scan at all |
| 2 | Partition metadata — partition exists, its row count and modification time | No scan |
| 3 | Partition-scoped aggregate — `COUNT`, `MAX`, `SUM` over one day | Scans one partition |
| 4 | Full-table aggregate | Scans the table |
| 5 | Row-level comparison against another table | Scans both |

A volume check written as a full-table `COUNT(*)` on a large fact table is rung 4 doing rung 1's job. See [[concepts/data_engineering/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]] for what that costs per run, multiplied by every run forever.

### Running the check against the right snapshot

A check must observe exactly the data the pipeline is about to publish. Two mistakes break this:

- **Racing the writer.** Measuring a table that is still being written gives a verdict about a half-finished state. Check the staged output *before* the swap, not the live table during the load.
- **Drifting parameters.** A check that computes `CURRENT_DATE()` independently will test a different partition than the pipeline wrote on a run that crosses midnight or is backfilled. Pass the run's logical date in as a parameter, the same one the transformation used.

## The Standard Checks

Most sanity-check suites are assembled from the same handful of assertions, each mapping to one of the six quality dimensions.

| Check | Asserts | Dimension | Typical failure it catches |
| --- | --- | --- | --- |
| **Row count non-zero** | The table has rows | Completeness | Upstream export produced an empty file; filter excluded everything |
| **Row count in range** | Volume is within a tolerance of the recent norm | Completeness | Partial load, duplicated load, upstream outage |
| **Freshness** | `max(event_time)` or the load timestamp is recent enough | Timeliness | Scheduler did not fire; source feed stopped silently |
| **Partition presence** | Today's (or the expected) partition exists | Timeliness | Late or skipped run that leaves a hole |
| **Key uniqueness** | The declared grain has no duplicates | Uniqueness | Re-run without idempotence; a join that fanned out |
| **Not-null on critical fields** | Required columns are populated | Completeness | Schema drift renamed a source column to `NULL` |
| **Range and domain** | Values fall within physical or business bounds; categoricals are in the known set | Validity | Unit change, sign flip, a new enum value from upstream |
| **Reconciliation** | A total agrees with an independent source — source vs. target count, sum of a measure vs. the system of record | Accuracy, Consistency | Mapping error in a migration; dropped rows mid-pipeline |
| **Schema shape** | Expected columns exist with expected types | Validity | Upstream added, removed, or retyped a column |
| **Distribution** | Null rate, distinct count, or mean has not shifted abnormally | Accuracy | A defect no absolute rule describes, visible only as drift |

Reconciliation deserves emphasis: it is the only check in the list that compares against something *outside* the pipeline, so it is the only one that can catch an error the pipeline is consistently making.

## Worked Example: A Daily Orders Pipeline

A concrete suite, written as plain SQL so it carries over to any engine or framework. Date arithmetic and the catalog view names differ between engines; nothing else here does.

**The pipeline.** An hourly export from the orders transactional system lands in `raw_orders_export`. `stg_orders` cleans and types it. `fct_orders` joins it to `dim_customer` and publishes, partitioned by `order_date`.

**The contract the checks enforce** — written down first, because a check is only an executable restatement of a contract that already exists:

- `fct_orders` has exactly one row per `order_id`. This is the **grain**, and it is the single most important sentence in this section.
- Yesterday's partition exists and is complete by 06:00.
- `order_status` is one of five known values.
- Every `customer_id` resolves to a row in `dim_customer`.
- `SUM(gross_amount)` for a day equals the source system's own daily total.

### 1. Ingestion: did the partition land, and is it fresh?

Partition presence is rung 2 on the cost ladder — every engine exposes partition names, row counts, and modification times in a catalog view, so this question is answered without reading a single row. Query that view rather than counting the table.

Freshness needs one aggregate over the landed partition, and returns a row only when it fails:

```sql
SELECT MAX(loaded_at) AS newest_record,
       CURRENT_TIMESTAMP - MAX(loaded_at) AS lag
FROM raw_orders_export
WHERE order_date = :run_date
HAVING CURRENT_TIMESTAMP - MAX(loaded_at) > INTERVAL '6' HOUR;
```

Six hours is the *error* threshold — the point at which publishing stale data is worse than publishing nothing. A second, tighter threshold (say two hours) should only warn. Collapsing the two into one value throws away the distinction between "late" and "broken".

### 2. Grain: is there exactly one row per order?

```sql
-- Returns rows only on failure, so an empty result is a pass.
SELECT order_id, COUNT(*) AS n
FROM fct_orders
WHERE order_date = :run_date      -- partition-scoped: rung 3, not rung 4
GROUP BY order_id
HAVING COUNT(*) > 1;
```

The other stateless assertions on the same table follow the same shape — `order_id IS NOT NULL`, `order_status` in the five known values, `customer_id` with no orphan against `dim_customer`. Most transformation frameworks let you declare these in configuration instead of writing each query, but the generated SQL is exactly the pattern above.

What matters is the severity assigned to each, and the split should be deliberate: a broken grain is an **error**, because every aggregate built on the table is now wrong. An unrecognized `order_status` is a **warn**, because the rows are probably fine and the enum is probably just out of date.

### 3. Volume: is today's row count plausible?

The stateful check — compared against a historical baseline, with weekday seasonality handled by only comparing like days:

```sql
WITH daily AS (
  SELECT order_date, COUNT(*) AS n
  FROM fct_orders
  WHERE order_date BETWEEN :run_date - INTERVAL '56' DAY AND :run_date
  GROUP BY order_date
),
baseline AS (
  SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY n) AS median_n
  FROM daily
  WHERE order_date < :run_date
    AND EXTRACT(DOW FROM order_date) = EXTRACT(DOW FROM :run_date)
)
SELECT d.n AS measured,
       b.median_n AS expected,
       (d.n - b.median_n) / b.median_n AS pct_deviation
FROM daily d CROSS JOIN baseline b
WHERE d.order_date = :run_date
  AND ABS((d.n - b.median_n) / b.median_n) > 0.20;
```

Two deliberate choices. Fifty-six days gives eight same-weekday samples, about the minimum for a stable baseline — a 28-day window gives four, and four samples is a reference that moves whenever one of them does. And a median rather than a mean, so a single outlier day does not drag the expectation with it.

### 4. Reconciliation: do the totals match the system of record?

This only works if the source emits its own totals. Asking for a small daily control-totals file alongside the data export is the cheapest high-value thing to negotiate with an upstream team:

```sql
SELECT s.order_count   AS source_count,
       t.order_count   AS target_count,
       s.gross_revenue - t.gross_revenue AS revenue_diff
FROM oltp_daily_control_totals s
CROSS JOIN (
  SELECT COUNT(*) AS order_count, SUM(gross_amount) AS gross_revenue
  FROM fct_orders
  WHERE order_date = :run_date
) t
WHERE s.order_date = :run_date
  AND (s.order_count <> t.order_count
       OR ABS(s.gross_revenue - t.gross_revenue) > 0.01);
```

### 5. An actual failure, step by step

This is where the layering pays off. One Tuesday the suite fires:

1. **06:04 — the gate blocks the publish.** The grain check on `fct_orders.order_id` returns 412 rows. The orchestrator aborts before the swap, so the serving table still holds Monday's data and no dashboard has moved.
2. **The volume check passed.** 412 duplicates out of 48,000 orders is +0.9% — nowhere near the 20% band. A volume check alone would have waved this through, which is the concrete reason the grain check exists.
3. **Fault localization comes free from the boundary layout.** The same uniqueness check on `stg_orders` passed, so the duplication was introduced *between* staging and the mart — that is, by the only thing that happens there, the join to `dim_customer`.
4. **The cause.** A late-arriving update created a second row for one customer in `dim_customer` with `is_current = TRUE`. The join fanned out every one of that customer's orders into two.
5. **The reconciliation check corroborates.** `revenue_diff` is non-zero by exactly that customer's daily total — confirming the duplicates are fabricated rows rather than genuinely missing orders in the source.
6. **Response.** The bad dimension rows are quarantined rather than deleted, `dim_customer` is rebuilt, and the run is replayed. Because the mart write is idempotent for a given `order_date`, the replay overwrites the partition cleanly instead of appending a second batch.
7. **The suite gets one check richer.** A uniqueness check on `dim_customer` where `is_current = TRUE` is added, moving detection one stage upstream — the real output of an incident is the check that would have caught it sooner.

The lesson generalizes: no single check would have produced this diagnosis. The *grain* check detected it, the *stage boundaries* localized it, the *reconciliation* check characterized it, and the *volume* check's silence was itself information.

## Where They Run

Sanity checks belong at boundaries — every point where data changes hands or changes shape.

1. **At ingestion.** Before anything is written, against the landed raw data: file arrived, non-empty, expected schema, expected partition. This is the cheapest place to stop a bad run.
2. **After each transformation stage.** Grain and uniqueness after a join, row-count delta after a filter or dedup. A join that silently fans out is the single most common way a correct-looking model becomes wrong.
3. **Before publishing.** The gate in front of the serving layer, run against the staged output. Pairing this with a write-to-staging-then-swap pattern means a failed check leaves the previous good version in place rather than a half-written one.
4. **After deployment.** A post-release check on the first production run, confirming that a change which passed in CI against a sample also holds against full volume.
5. **Continuously, as monitoring.** The same assertions run on a schedule against live tables, catching decay — a feed that stops, a source that starts emitting nulls — between pipeline runs.

In a transformation framework that runs tests as part of the build — [[concepts/data_engineering/dbt/dbt|dbt]] being one common example — the first three collapse into a single mechanism: the assertions are declared beside the model they guard, and the build fails if any of them does.

## Setting Thresholds

A sanity check is only as good as its threshold, and thresholds are where these suites usually fail.

- **Prefer relative to absolute.** "Within 20% of the trailing 7-day median" survives growth; "at least 10,000 rows" is correct for one quarter and then silently becomes a no-op.
- **Account for known seasonality.** Compare like with like — same weekday, same period — or every Monday morning is an incident.
- **Separate `warn` from `error`.** Two thresholds per check: a wide one that blocks the pipeline, a narrow one that only notifies. The blocking threshold must be loose enough that firing genuinely means "broken".
- **Make freshness windows match the SLA, not the schedule.** An hourly job with a four-hour tolerance is a deliberate choice about how much staleness consumers can absorb; setting the tolerance to one hour just alerts on every retry.
- **Review thresholds when the pipeline changes.** A threshold set against old volumes is a threshold that no longer means what it says.

> [!warning] Alert fatigue is the failure mode, not false negatives.
> A suite that fires on routine variation gets muted or routinely overridden, and then it protects nothing. Fewer checks that are trusted and act as hard gates beat many checks that everyone ignores. If a check cannot be tuned to near-zero false alarms, it belongs in monitoring, not in the gate.

## When a Check Fails

Detection is worthless without a defined response, and the response has to be decided *before* the alert, not during it.

- **Block or warn** must be set per check, as a deliberate statement of what is unacceptable to publish. See the open question below.
- **Quarantine rather than discard.** Route failing data to a holding area so it can be inspected and replayed; a check that drops rows to make itself pass has become the defect.
- **Make the run idempotent.** Re-running after a fix must produce the same result as a clean first run, or every incident leaves duplicates behind.
- **Route to a named owner.** An alert into a shared channel has no owner; [[concepts/data_governance/data_stewardship|stewardship]] is what turns a failed check into a resolved one.
- **Record the failure.** Check outcomes over time are the measurement that the quality lifecycle's *monitor* stage depends on — and the evidence for whether a threshold is tuned correctly.

## Pitfalls

- **Checking the pipeline instead of the data.** "The job succeeded" is not a sanity check. Exit code zero and an empty table coexist comfortably.
- **Testing only in CI against a sample.** Volume-dependent failures — skew, memory, duplicate keys that only appear at scale — are invisible against a dev slice.
- **Full-scan checks on large tables.** On a consumption-priced warehouse, a per-run full scan to count rows can cost more than the transformation; prefer table metadata, partition-scoped counts, or approximate aggregates. See [[concepts/data_engineering/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]].
- **No check on the grain.** Uniqueness of the declared key is the single highest-value assertion in most pipelines and the one most often omitted, because the grain was never written down.
- **Checks that were never updated.** A rule asserting a column's enum values, written before upstream added a category, fails on correct data — and teaches the team to override failures.
- **Never testing the test.** A check nobody has watched fail is a check nobody has verified. Corrupt the data deliberately in a dev environment and confirm the run actually aborts and the alert actually reaches a named human; silently broken checks are indistinguishable from passing ones.
- **Letting the baseline absorb the defect.** A stateful check whose history includes failed runs drifts toward the bad value, so a degradation that persists for a week becomes the new normal and the check goes quiet exactly when it matters.
- **Treating the sanity suite as the quality programme.** Passing every boundary check says nothing about whether the numbers are right, only that they are not obviously wrong.

## Open Questions & Disagreements

- **Should a failed sanity check block the pipeline or only alert?** One position holds that publishing known-bad data is strictly worse than publishing nothing, so the check is a circuit breaker that halts the run. The other holds that stale-but-complete data serves consumers better than an empty or missing table, so the check should alert and let the previous version stand. Both are defensible and the answer depends on the consumer's tolerance for staleness versus incorrectness; this note does not pick a winner, and the choice should be recorded per dataset rather than set globally.
- **The boundary between "sanity check", "smoke test", and "data test" is not standardized.** The usage described here — cheap, aggregate, boundary-placed — is the common one in data engineering, but no authoritative source fixes the terms, and in software testing "sanity test" carries a different meaning (a narrow re-check after a change). Unverified: this note is written from general practice rather than a cited specification, and is flagged here rather than presented as settled.

## Related Concepts

- [[concepts/data_governance/data_quality|Data Quality]] — the parent discipline; every check here maps to one of its six dimensions, and the lifecycle's *monitor* stage is where these checks live
- [[concepts/data_engineering/dbt/dbt|dbt (Data Build Tool)]] — one common implementation, where declaring the assertions beside the model makes the gate and the transformation the same artifact
- [[concepts/data_governance/data_stewardship|Data Stewardship]] — names the owner an alert routes to, without which a failed check is only a log line
- [[concepts/data_governance/metadata_management|Metadata Management]] — check definitions, thresholds, and outcomes are themselves metadata, and lineage is what scopes the blast radius when one fails
- [[concepts/data_engineering/bigquery_cost_monitoring|BigQuery Usage and Cost Monitoring]] — checks that run on every pipeline run are a recurring scan cost, and the thing that makes metadata-based counts worth the effort
