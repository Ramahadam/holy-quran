CREATE TABLE anonymous_feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feedback_text TEXT NOT NULL CHECK (length(feedback_text) BETWEEN 1 AND 2000),
  platform TEXT NOT NULL CHECK (length(platform) BETWEEN 1 AND 32),
  app_version TEXT NOT NULL CHECK (length(app_version) BETWEEN 1 AND 64),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX anonymous_feedback_created_at_idx
  ON anonymous_feedback (created_at DESC);
