-- api_cost_log schema (run once in your Postgres)
CREATE TABLE IF NOT EXISTS api_cost_log (
  id                  BIGSERIAL PRIMARY KEY,
  provider            TEXT        NOT NULL,
  endpoint            TEXT        NOT NULL,
  method              TEXT        NOT NULL DEFAULT 'GET',
  workflow_name       TEXT        NOT NULL DEFAULT 'unassigned',
  execution_id        TEXT,
  attempt             INT         NOT NULL DEFAULT 1,
  status_code         INT,
  success             BOOLEAN     NOT NULL,
  cost_usd            NUMERIC(12,6),
  pricing_basis       TEXT,          -- 'usage.cost' | price-table rule name | NULL = unknown
  usage               JSONB,
  requested_at        TIMESTAMPTZ NOT NULL,
  logged_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  needs_reconciliation BOOLEAN    NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_acl_provider_time ON api_cost_log (provider, requested_at DESC);
CREATE INDEX IF NOT EXISTS idx_acl_workflow_time ON api_cost_log (workflow_name, requested_at DESC);

-- Monthly rollup you'll actually care about:
-- SELECT provider, date_trunc('month', requested_at) m, SUM(cost_usd) total,
--        SUM(CASE WHEN success THEN 0 ELSE 1 END) failed_billed
-- FROM api_cost_log GROUP BY 1,2 ORDER BY m DESC, total DESC;
