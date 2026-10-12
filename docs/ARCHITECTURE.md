# Architecture

This demo is built so that the reliability behaviour is visible in n8n itself. Orchestration,
branching, retries and replay are all expressed as n8n nodes. Code nodes are deliberately small
and limited to local work: normalisation, validation, hashing, classification, redaction,
response formatting and delay calculation.

## Workflow map

| Workflow | Role |
|---|---|
| `main-workflow.json` | Intake, validation, claim, routing, side effects, completion |
| `retry-subworkflow.json` | Reusable retry orchestration for a single HTTP attempt chain |
| `replay-workflow.json` | Resume failed work from the first missing receipt |
| `monitor-workflow.json` | Detect silent failures on a schedule |
| `error-core-workflow.json` | Error Trigger handling, referenced as the Error Workflow |

## Main workflow stages

```
Webhook -> Validate -> Claim -> Route -> CRM -> Alert -> Audit -> Complete
```

1. **Webhook intake.** A webhook trigger accepts the lead payload.
2. **Normalise.** A small Code node trims and canonicalises fields so downstream logic sees a
   consistent shape.
3. **Validate.** Required fields and formats are checked. Invalid payloads take an explicit
   rejection branch and return a defined error response rather than failing silently.
4. **Build idempotency key.** A stable SHA-256 key is derived from the lead's identity fields,
   so the same logical lead always produces the same key.
5. **Atomic claim.** The key is claimed atomically. If the claim is already held, the workflow
   routes to a duplicate response instead of repeating side effects.
6. **Route.** A Switch node routes on the claim result — proceed, duplicate, or already in
   progress.
7. **Side effects.** The CRM record is written, the owner alert is sent, and an audit receipt
   is recorded. These are the operations that must not be duplicated.
8. **Completion.** Completion is only allowed once the expected receipts exist.

## Duplicate protection

Idempotency is enforced in two layers:

- **Deterministic key.** The same lead always hashes to the same key, so retries and re-delivery
  converge on one identity.
- **Atomic claim.** Claiming is a single atomic operation, which is what makes concurrent
  delivery safe. Two simultaneous deliveries of the same lead cannot both proceed.

Sequential, overlapping and concurrent duplicates are all covered by the acceptance suite.

## Retry sub-workflow

Retry behaviour lives in a separate, callable workflow so any caller can reuse it. It performs
**one initial HTTP attempt plus three controlled retries**:

1. `Loop Over Items` drives the attempts.
2. `HTTP Request` performs one attempt. It is configured not to throw on failure, so the
   response body can be inspected rather than the workflow aborting.
3. A classify step records the result, the timing, and the backoff required.
4. An `IF` node decides whether another attempt is safe.
5. `Wait` applies the backoff before looping.
6. When attempts are exhausted, the workflow returns an explicit exhausted result.

## Failure classification

Results are classified rather than treated as a single "failed" state:

- **Success** — proceed to completion.
- **Transient** (for example 503, or a timeout) — retry with backoff.
- **Rate limited** (429) — retry honouring the retry-after signal.
- **Permanent** — fail fast; retrying would not help.
- **Configuration** — surface immediately, since the workflow cannot resolve it by retrying.

Failing fast on permanent errors avoids burning the retry budget on work that cannot succeed.

## Replay design

Replay exists so that a failure does not force the work to be redone from scratch. The replay
workflow inspects recorded receipts and determines the **first missing step**, then resumes from
that point. Work whose receipt already exists is skipped. This is what prevents replay from
duplicating successful side effects.

## Receipt and completion rule

Completion is receipt-gated. The workflow does not declare a lead complete until the expected
receipts are present — one CRM record, one owner alert, and one completion audit. If a required
receipt is missing, the lead is treated as incomplete and remains eligible for replay.

## Monitoring

`monitor-workflow.json` runs on a schedule and looks for silent failures: work that stopped
without producing an explicit error or a completion receipt. Its purpose is to surface the
failures that would otherwise go unnoticed until someone noticed missing data.

## Design notes

- Orchestration is native n8n; there is no hidden external orchestration layer.
- Code nodes perform local, deterministic work only — no network calls, sleeps or retry loops
  inside them.
- Destinations in this demo are local fixtures serving synthetic data. Production connector
  behaviour, authentication, and scale are out of scope for this demonstration.
