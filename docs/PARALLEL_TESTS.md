# Skycom Parallel Test Execution

> **Status**: Active. `parallel_tests` is a local execution optimization only.
> `bundle exec rspec ...` remains the source of truth for spec identity —
> all other docs keep `rspec` examples. This doc covers only how the AI agent
> runs tests faster locally. It is runner-swappable; a future tool replaces
> this doc, not the `rspec` examples elsewhere.

## 1. Rule

- **ALWAYS** run tests locally with `bundle exec parallel_rspec -n 10 [paths]`.
  Full suite ~5m vs ~20m single-process. `-n 10` is the default — the dev
  machine handles 10 workers.
- **NEVER** bare `parallel_rspec` without `bundle exec` — it can raise errors.
- **NEVER** `bundle exec rspec` for verification (suites, subsets, single files)
  — single process is too slow. `rspec` appears in docs only as spec identity.
- **NEVER** `docker exec ... rspec` — in dev, compose provides services only;
  `web` + `job` run locally via `bin/dev`. Run from the repo root directly.
- **NEVER** re-run parallel DB setup except for the §3 cases — missing
  worker DBs (§3.1) or migration failure (§3.2).

## 2. Commands

| Scope | Command |
|-------|---------|
| Full suite | `bundle exec parallel_rspec -n 10` |
| Subset | `bundle exec parallel_rspec -n 10 spec/features/admin spec/features/mobile` |
| Single file / line | `bundle exec parallel_rspec -n 10 spec/models/company_spec.rb` |

Always keep `-n 10` and the `bundle exec` prefix. Single files also go through
parallel — worker isolation (`TEST_ENV_NUMBER`) and retries (§5) only activate
under parallel.

## 3. Setup & migration recovery

### 3.1 First-time setup (once — already done, do not repeat)

Only when worker DBs are missing (e.g. `skycom_test2` does not exist):

```bash
RAILS_ENV=test bundle exec rake "parallel:create[10]"
RAILS_ENV=test bundle exec rake "parallel:load_schema[10]"
```

These create/load `skycom_test`, `skycom_test2` … `skycom_test10` (+ `queue_test*`,
per-worker SQLite cable/cache). If the DBs already exist, skip both lines.

### 3.2 Migration recovery (parallel_rspec fails on migration)

When `bundle exec parallel_rspec -n 10` fails with `PendingMigrationError`,
`relation does not exist`, or a schema mismatch right after a new migration,
do a full reset — drop everything, then recreate from the current schema:

```bash
RAILS_ENV=test bundle exec rake "parallel:drop[10]"
RAILS_ENV=test bundle exec rake "parallel:create[10]"
RAILS_ENV=test bundle exec rake "parallel:load_schema[10]"
```

`load_schema` is the default (fast, deterministic from `db/schema.rb`). When
verifying the migration itself replays cleanly, use `migrate` instead of the
last line:

```bash
RAILS_ENV=test bundle exec rake "parallel:migrate[10]"
```

Always keep the `RAILS_ENV=test` prefix and `[10]` (10 workers, matches
`-n 10`). All four commands fan out to `skycom_test*` + `queue_test*` plus
the per-worker SQLite cable/cache files.

### 3.3 Secondary schemas are off-limits

AI is blocked from editing `db/queue_schema.rb`, `db/cable_schema.rb`,
`db/cache_schema.rb`, and `db/rails_pulse_schema.rb` — they are gem-owned
(Solid Queue / Cable / Cache / Rails Pulse). If a migration run reports an
error relating to those files, it is OK to ignore: only `db/schema.rb` +
`db/migrate/*` matter for the recovery in §3.2. Never hand-edit a secondary
schema to "fix" a parallel failure.

## 4. Prerequisites

```bash
docker compose up -d   # services only: postgres, redis, meilisearch, etc.
bin/dev                # web + css + job locally (compose web/job are ignored in dev)
```

No `docker exec` for tests — the test process runs on the host against the
compose services.

CI is out of scope: CI stays single-process (`bundle exec rspec` in
`docker-compose.rspec-test.yml`) because GitHub buckets parallelize there.

## 5. Isolation mechanics (why `-n 10` is safe)

| Layer | Mechanism | File |
|-------|-----------|------|
| Postgres | DB name suffixed with `TEST_ENV_NUMBER` (`skycom_test`, `skycom_test2`…) | `config/database.yml` |
| SQLite cable/cache | Per-worker file (`test_cable2.sqlite3`, `test_cache2.sqlite3`…) | `config/database.yml` |
| Redis | Per-worker DB number from `TEST_ENV_NUMBER` (`/0`, `/2`…) | `config/redis/shared.yml` |
| Meilisearch | Per-worker index suffix (`Product_test`, `Product_test2`…) | `config/initializers/meilisearch.rb` |
| Runtime balancing | `RuntimeLogger` writes `tmp/parallel_runtime_rspec.log` (gitignored via `/tmp/*`) | `.rspec_parallel` |
| Retries | Enabled only when `TEST_ENV_NUMBER` is present, count 5 | `spec/retry_helper.rb` |

## 6. Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `relation does not exist` on worker N | Worker DB not migrated → run the two setup lines in §3 |
| `PendingMigrationError` / schema mismatch after a new migration | Worker DBs drifted → full reset per §3.2 (`drop[10]` → `create[10]` → `load_schema[10]`, or `migrate[10]` to verify the migration replays) |
| Migration error mentions `queue/cable/cache/rails_pulse_schema.rb` | Secondary schemas are gem-owned and off-limits (§3.3) → OK to ignore; only `db/schema.rb` + `db/migrate/*` matter |
| Bare `parallel_rspec` raises load error | Missing `bundle exec` prefix → always `bundle exec parallel_rspec` |
| Flaky feature passes alone, fails in suite | Retries only run under parallel — repro must also use `bundle exec parallel_rspec -n 10`, never bare `rspec` (see `docs/FLAKY_TESTS.md`) |
| Stale Meilisearch hits across workers | Index suffix missing → check `TEST_ENV_NUMBER` is passed through (see `config/initializers/meilisearch.rb`) |

---

*See also: `docs/FLAKY_TESTS.md` (spec identity + flake patterns, `rspec` examples stay as-is),
`docs/MEILISEARCH.md` §6 (test indexing), `docs/CACHE.md` (Redis/DB test isolation).*
