# Paid API Cost Logger — n8n Reusable Sub-Workflow

One sub-workflow owns every paid HTTP call in your n8n setup. Callers stay one node clean;
cost logging lives in exactly one place. Logs successes AND failed-but-billed calls (providers
bill failures — most setups never track that).

## Why this design
- **Inversion pattern:** the sub-workflow makes the call itself (method/url/body passed in),
  so its error branch automatically catches failed-but-billed calls.
- **Cost sources, in order:** provider-returned usage cost → price-table fallback → `null`
  with `needs_reconciliation = true` (never silently show a wrong number).
- **Attempts logged separately** so retry storms can't hide in averages.

## Files
- `paid_api_cost_logger.subworkflow.json` — import into n8n (Workflows → Import from File)
- `schema.sql` — one-time Postgres setup
- `caller_example.json` — what callers pass via Execute Workflow node

## Setup (5 min)
1. Run `schema.sql` in Postgres.
2. Import the workflow JSON; create your Postgres credential; select it in both Postgres nodes.
3. In any workflow: Execute Workflow node → target this sub-workflow → pass the fields from
   `caller_example.json`.
4. Optionally pin per-provider rates in `price_table` or rely on usage costs.

## Verified
- Workflow JSON structure validated (all node refs/connections resolve).
- Cost logic unit-tested with node (4 cases: usage-cost, price-table fallback,
  failed-but-billed, unknown-cost → reconciliation flag).

Part of my reliability-first n8n portfolio: https://github.com/jadusaa/n8n-reliability-lead-routing-demo
