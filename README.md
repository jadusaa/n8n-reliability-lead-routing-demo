# n8n Reliability Lead Routing Demo

I built this self-contained n8n demo to show how I approach workflow reliability, not just the
happy path. It validates and routes incoming leads, prevents duplicate processing, retries
temporary failures, records completion receipts, and can safely replay failed work without
repeating successful side effects.

### What it demonstrates

- **Native n8n orchestration** — branching, routing and sub-workflow calls live in visible
  n8n nodes, not hidden inside one large Code node or an external script.
- **REST / webhook handling** — inbound webhook intake with normalisation, validation and
  explicit response contracts.
- **Duplicate protection / idempotency** — stable SHA-256 idempotency keys plus an atomic
  claim, so the same lead cannot be processed twice.
- **Retries with backoff** — a reusable retry sub-workflow performs one initial attempt plus
  three controlled retries, classifying each result before deciding to retry.
- **Partial-failure recovery and safe replay** — a replay path resumes from the first missing
  receipt instead of restarting work that already succeeded.
- **Testing and operational monitoring** — an acceptance suite covers the failure modes, and a
  monitor workflow detects silent failures.

### Architecture

```
Webhook -> Validate -> Claim -> Route -> CRM -> Alert -> Audit -> Complete
```

Retryable side effects are delegated to a reusable retry sub-workflow (`Loop Over Items` ->
`HTTP Request` -> classify -> `IF` -> backoff -> `Wait` -> loop). Failures that exhaust their
retries are routed to a failure path, and the replay workflow can resume them from the first
missing receipt. A separate monitor workflow watches for silent failures.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full walkthrough of each stage.

### Reliability test

23 acceptance tests passed, covering validation, duplicates, concurrency, transient failures,
partial failures, and replay. See [`docs/TESTING.md`](docs/TESTING.md) and
[`evidence/acceptance-summary.json`](evidence/acceptance-summary.json).

No production traffic or client systems are claimed.

### Tech

- n8n
- JavaScript
- REST APIs
- Webhooks
- JSON
- SQLite
- Self-hosted / local test environment

### Scope

This is a self-built portfolio demonstration using synthetic data, not client work.

### Repository layout

```
workflows/   sanitized n8n workflow exports (main, retry, replay, monitor, error)
docs/        architecture, runbook and testing notes
evidence/    sanitized acceptance summary
```

### Contact

Built by Girot.
