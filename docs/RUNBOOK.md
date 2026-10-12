# Runbook

How to stand this demo up locally and exercise each behaviour. Paths are generic — substitute
your own instance URL and credentials.

## 1. Prerequisites

- A local, self-hosted n8n instance (built and tested on n8n `1.121.3`).
- A place to store fixture state — the demo uses a small local HTTP fixture service backed by
  SQLite. Any store with a compare-and-set operation works.
- An HTTP endpoint that stands in for the CRM and the notification sink. The demo uses local
  fixtures serving synthetic data.

## 2. Import the workflows

Import each file from `workflows/` in this order, so that sub-workflow references resolve:

1. `retry-subworkflow.json`
2. `error-core-workflow.json`
3. `replay-workflow.json`
4. `monitor-workflow.json`
5. `main-workflow.json`

In the n8n UI: **Workflows -> Import from File**, then select the JSON.

Note: the exports are intentionally stored **inactive** so they import safely. Runtime
activation must be verified after import — the export flag alone is not proof of runtime state.

## 3. Point the workflows at your environment

Each HTTP Request node has a base URL. Replace the placeholder with your own:

```
CRM base URL:          http://<your-host>:<port>
Notification sink URL: http://<your-host>:<port>
```

Keep credentials in the n8n credential store. Do not hardcode them into nodes or into the
workflow JSON.

## 4. Run a synthetic lead

1. Activate `main-workflow.json`.
2. Copy the webhook trigger's production URL.
3. POST a synthetic lead payload:

```bash
curl -X POST "<your-webhook-url>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Synthetic Lead",
    "service": "demo-service",
    "postcode": "00000",
    "team": "Team A",
    "priority": "normal"
  }'
```

4. Expected: a success response, one CRM record, one owner alert, and one completion audit
   receipt.

## 5. Verify duplicate protection

Send the exact same payload again.

Expected: the workflow routes to the duplicate branch and returns a duplicate-ignored response.
No second CRM record, alert or audit is created.

Sending two copies at the same time exercises the atomic claim: one proceeds, the other is
rejected as in-progress or duplicate.

## 6. Trigger a forced failure

To see retry behaviour, make the destination fail. Add a query flag your fixture understands,
for example:

```bash
curl -X POST "<your-webhook-url>?force_status=503" \
  -H "Content-Type: application/json" \
  -d '{ "...same synthetic payload..." }'
```

Expected: the retry sub-workflow performs one initial attempt plus three controlled retries,
applying backoff between attempts, then returns an exhausted result. The main workflow routes
the lead to its failure path and does not write a CRM record.

## 7. Inspect the replay

1. Clear the forced failure so the destination responds normally.
2. Trigger the replay workflow for the failed lead.
3. Expected: replay starts from the first missing receipt — it does not redo work whose receipt
   already exists.

Check that after replay there is still exactly one CRM record, one owner alert and one
completion audit.

## 8. Verify completion

A lead is complete only when all expected receipts exist. Check:

- exactly one CRM record for the idempotency key,
- exactly one owner alert,
- exactly one completion audit,
- the lead's state shows completed.

If a receipt is missing, the lead should still be eligible for replay rather than marked done.

## 9. Monitoring

Activate `monitor-workflow.json`. On its schedule it looks for work that stopped without an
explicit error or a completion receipt, and raises an alert for those silent failures.

## Operational notes

- The exports are inactive by design; activate them deliberately.
- Destinations here are local fixtures with synthetic data. Production authentication, TLS,
  scale, backup and availability are out of scope for this demo.
- Keep the credential store out of version control. `.gitignore` already excludes `.env`,
  database files and runtime state.
