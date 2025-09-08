CREATE TABLE IF NOT EXISTS expense (
  id TEXT NOT NULL PRIMARY KEY,
  dt TEXT, account TEXT, payee TEXT, category TEXT,
  payment NUMERIC, deposit NUMERIC, net NUMERIC, quarter INT,
  month INT, day TEXT
);
CREATE index idx_dt ON expense(dt);

CREATE VIRTUAL TABLE payees using fts5(id UNINDEXED, payee);
