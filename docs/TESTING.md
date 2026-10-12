# Testing

## Result

**23 total / 23 passed / 0 failed.**

The suite is the unchanged acceptance runner for this build. It runs against the local
self-hosted n8n instance using synthetic fixture data.

Machine-readable summary: [`../evidence/acceptance-summary.json`](../evidence/acceptance-summary.json)

## What is covered

| Category | What it verifies |
|---|---|
| Input validation | Required fields and formats; rejection paths return defined error responses |
| Duplicate handling | Sequential, overlapping and concurrent duplicates do not repeat side effects |
| Idempotency | The same lead always produces the same key and converges on one identity |
| Atomic claim | Concurrent deliveries cannot both proceed past the claim |
| Retry orchestration | One initial attempt plus three controlled retries, with correct attempt accounting |
| Backoff | Backoff values are calculated and applied between attempts |
| Transient errors | 503 and timeout-style failures classify as retryable |
| Rate limiting | 429 is classified and honoured rather than treated as permanent |
| Permanent errors | Fail fast, without exhausting the retry budget |
| Partial failure | Work that completed is not redone when a later step fails |
| Safe replay | Replay resumes from the first missing receipt |
| No repeated side effects | Replay and retry do not duplicate CRM writes, alerts or audits |
| Completion receipts | Completion is receipt-gated; incomplete work stays eligible for replay |
| Monitoring | Silent failures are detectable by the monitor workflow |

## Architecture preflight

The suite also asserts the build's shape before running behaviour: the main, retry, replay and
monitor workflows are active, the Error Trigger workflow is referenced and inactive by design,
retry orchestration is native, no critical nodes are disabled, and no Code node contains network
calls or retry loops.

## How to run it

The suite is not included in this repository because the acceptance runner and its fixtures
contain local environment assumptions that are not useful to a reader. The summary above records
the real result from the validated build. Anyone reviewing the work should treat the exported
workflows in [`../workflows`](../workflows) as the inspectable evidence, and the summary as the
recorded outcome.
