CREATE TABLE IF NOT EXISTS submissions (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  display_name TEXT NOT NULL,
  window TEXT NOT NULL,
  input_tokens INTEGER NOT NULL,
  output_tokens INTEGER NOT NULL,
  cache_read_tokens INTEGER NOT NULL,
  captured_at TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_latest_name_plan
  ON submissions (plan_id, display_name, window);

CREATE INDEX IF NOT EXISTS idx_ladder
  ON submissions (plan_id, window, output_tokens DESC, input_tokens DESC);
