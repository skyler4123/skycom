# Environment Centralization — Implementation Plan

> Self-contained plan. A fresh session can execute it without chat history.
> Decision changes must be recorded here.

---

## 1. Goal

Every environment-backed value is declared exactly once, in
`config/initializers/constants.rb`, using one rule: **ENV → `Rails.application.credentials` → hardcoded default**.
Services, models, controllers, jobs, initializers, seeds and specs use only the constant — never ENV.
The rule, the full catalog, and the pre-boot exceptions are documented in `docs/ENVIRONMENT.md`.

Why ENV first: operators must be able to override any value per shell/container without re-encrypting
credentials. Credentials remain the durable secret store; defaults keep dev/test bootable.

---

## 2. Locked decisions

| Decision | Choice |
|---|---|
| Declaration location | `config/initializers/constants.rb`, one plain assignment per variable |
| Resolver abstraction | **None** — no `Skycom::Config` module, no helper methods |
| Precedence | `ENV["X"].presence \|\| Rails.application.credentials.dig(:x) \|\| default` |
| Constant name | Identical to the ENV name (`MEILISEARCH_HOST`) |
| Credential key | ENV name downcased symbol (`:meilisearch_host`); explicit override for `AWS_ENDPOINT_URL` → `:aws_endpoint` |
| Blank ENV value | Treated as unset (`.presence`) |
| Lazy YAML (`storage.yml`, `redis/shared.yml`, `queue.yml`) | Uses the constants |
| Pre-boot / out-of-band files | Keep the inline rule (`database.yml`, `environments/*.rb`, `puma.rb`, `boot.rb`, `spec/rails_helper.rb`) |
| Production defaults | One explicit warning block at the bottom of the env section (no helper) |
| Guardrail | `bin/check_env` + CI lint step + `AGENTS.md` pre-commit bullet |
| Test flags | `ActiveModel::Type::Boolean` for strict `"false"` handling; `SKIP_DB_SEED: true` in the rspec compose file |
| TDD exception | Pure config assignments are the TDD skill's documented "configuration files" exception; the spec proves ENV precedence + defaults + catalog completeness, and `bin/check_env` gets its own check |

---

## 3. Current state

### 3.1 Files

| File | Current role |
|---|---|
| `config/initializers/constants.rb` | Domain constants; only two env-backed values (`WEBHOOK_*_SECRET`) |
| `config/initializers/meilisearch.rb` | ENV + credentials + default inline |
| `config/initializers/websocket.rb` | ENV + credentials + default inline for 3 Centrifugo values |
| `config/initializers/omniauth.rb` | ENV-only for Google OAuth |
| `config/initializers/opentelemetry.rb` | Writes `OTEL_*` defaults into ENV |
| `config/initializers/mission_control.rb` | Hardcoded `dev` / `secret` |
| `app/services/payments/mock_qr_gateway.rb` | ENV + credentials + default for 2 URLs |
| `app/services/payments/mock_redirect_gateway.rb` | ENV + credentials + default for 2 URLs |
| `config/storage.yml` | Credentials + defaults for S3/RustFS |
| `config/redis/shared.yml` | Credentials + defaults per environment |
| `config/queue.yml` | `ENV.fetch("JOB_CONCURRENCY", 1)` |
| `config/database.yml` | Credentials + defaults for Postgres; `ENV["TEST_ENV_NUMBER"]` |
| `db/seeds.rb` | `ENV.fetch("SKIP_DB_SEED") { false }` |
| `spec/retry_helper.rb` | `ENV["TEST_ENV_NUMBER"]` |
| `spec/selenium_helper.rb` | `ENV.fetch("TEST_RUN_INSIDE_DOCKER") { false }` |
| `spec/system/mock_api_connection_spec.rb` | Own `MOCK_API_PING_URL` constant |

### 3.2 Pain points

- The same precedence chain is rewritten in 9 files with slightly different semantics (`||` vs `fetch`).
- Two values (`WEBHOOK_*_SECRET`) are already constants while the rest are not.
- Values that only live in credentials (Postgres, Redis, S3) cannot be overridden from the CLI.
- Nobody can see the full env surface in one place.

---

## 4. Target behavior

### 4.1 Declaration pattern

```ruby
# --- Meilisearch ---
MEILISEARCH_HOST = ENV["MEILISEARCH_HOST"].presence ||
  Rails.application.credentials.dig(:meilisearch_host) ||
  "http://localhost:7700"

MEILISEARCH_API_KEY = ENV["MEILISEARCH_API_KEY"].presence ||
  Rails.application.credentials.dig(:meilisearch_api_key) ||
  "skycom_master_key_password_2026"

# --- Typed values ---
JOB_CONCURRENCY = (
  ENV["JOB_CONCURRENCY"].presence ||
  Rails.application.credentials.dig(:job_concurrency) ||
  1
).to_i

TEST_RUN_INSIDE_DOCKER = ActiveModel::Type::Boolean.new.cast(
  ENV["TEST_RUN_INSIDE_DOCKER"].presence ||
  Rails.application.credentials.dig(:test_run_inside_docker) ||
  false
)
```

### 4.2 Production warning (explicit block, no helper)

```ruby
if Rails.env.production?
  {
    "MEILISEARCH_API_KEY" => :meilisearch_api_key,
    "CENTRIFUGO_API_KEY" => :centrifugo_api_key,
    "CENTRIFUGO_TOKEN_HMAC_SECRET_KEY" => :centrifugo_token_hmac_secret_key,
    "WEBHOOK_BANK_PAYMENT_SECRET" => :webhook_bank_payment_secret,
    "WEBHOOK_REDIRECT_PAYMENT_SECRET" => :webhook_redirect_payment_secret,
    "AWS_SECRET_ACCESS_KEY" => :aws_secret_access_key,
    "MISSION_CONTROL_PASSWORD" => :mission_control_password,
    "OTEL_EXPORTER_OTLP_HEADERS" => :otel_exporter_otlp_headers
  }.each do |env_key, credential_key|
    next if ENV[env_key].present? || Rails.application.credentials.dig(credential_key).present?

    Rails.logger.warn("[env] #{env_key} is unset; using its compiled-in development default.")
  end
end
```

### 4.3 Consumer rule

Any Ruby file outside `config/initializers/constants.rb` that needs one of these values
references the constant. `bin/check_env` enforces it.

---

## 5. Catalog

### 5.1 Declared as constants

| ENV | Constant | Credential key | Default | Read by |
|---|---|---|---|---|
| `MEILISEARCH_HOST` | `MEILISEARCH_HOST` | `meilisearch_host` | `http://localhost:7700` | `meilisearch.rb` |
| `MEILISEARCH_API_KEY` | `MEILISEARCH_API_KEY` | `meilisearch_api_key` | `skycom_master_key_password_2026` | `meilisearch.rb` |
| `CENTRIFUGO_API_KEY` | `CENTRIFUGO_API_KEY` | `centrifugo_api_key` | `skycom_super_secret_api_key_2026` | `websocket.rb` |
| `CENTRIFUGO_ENDPOINT` | `CENTRIFUGO_ENDPOINT` | `centrifugo_endpoint` | `http://localhost:8000/api` | `websocket.rb` |
| `CENTRIFUGO_TOKEN_HMAC_SECRET_KEY` | `CENTRIFUGO_TOKEN_HMAC_SECRET_KEY` | `centrifugo_token_hmac_secret_key` | `skycom_jwt_hmac_secret_token_key_2026` | `websocket.rb` |
| `GOOGLE_CLIENT_ID` | `GOOGLE_CLIENT_ID` | `google_client_id` | `nil` | `omniauth.rb` |
| `GOOGLE_CLIENT_SECRET` | `GOOGLE_CLIENT_SECRET` | `google_client_secret` | `nil` | `omniauth.rb` |
| `MOCK_QR_GATEWAY_URL` | `MOCK_QR_GATEWAY_URL` | `mock_qr_gateway_url` | `http://localhost:4000/api/v1/bank/qr-generate` | `mock_qr_gateway.rb` |
| `MOCK_QR_WEBHOOK_URL` | `MOCK_QR_WEBHOOK_URL` | `mock_qr_webhook_url` | `http://192.168.0.100:3000/webhooks/payments/mock_qr_gateway` | `mock_qr_gateway.rb` |
| `MOCK_REDIRECT_GATEWAY_URL` | `MOCK_REDIRECT_GATEWAY_URL` | `mock_redirect_gateway_url` | `http://localhost:4000/api/v1/bank/redirect-session` | `mock_redirect_gateway.rb` |
| `MOCK_REDIRECT_WEBHOOK_URL` | `MOCK_REDIRECT_WEBHOOK_URL` | `mock_redirect_webhook_url` | `http://192.168.0.100:3000/webhooks/payments/mock_redirect_gateway` | `mock_redirect_gateway.rb` |
| `MOCK_API_PING_URL` | `MOCK_API_PING_URL` | `mock_api_ping_url` | `http://localhost:4000/api/v1/ping` | `spec/system/mock_api_connection_spec.rb` |
| `WEBHOOK_BANK_PAYMENT_SECRET` | `WEBHOOK_BANK_PAYMENT_SECRET` | `webhook_bank_payment_secret` | `local_secure_dev_secret` | webhook controllers |
| `WEBHOOK_REDIRECT_PAYMENT_SECRET` | `WEBHOOK_REDIRECT_PAYMENT_SECRET` | `webhook_redirect_payment_secret` | `local_secure_dev_secret` | webhook controllers |
| `JOB_CONCURRENCY` | `JOB_CONCURRENCY` | `job_concurrency` | `1` | `queue.yml` |
| `REDIS_URL_PRODUCTION` | `REDIS_URL_PRODUCTION` | `redis_url_production` | `redis://127.0.0.1:6379/0` | `redis/shared.yml` |
| `REDIS_URL_DEVELOPMENT` | `REDIS_URL_DEVELOPMENT` | `redis_url_development` | `redis://127.0.0.1:6379/0` | `redis/shared.yml` |
| `REDIS_URL_TEST` | `REDIS_URL_TEST` | `redis_url_test` | `redis://127.0.0.1:6379/0` | `redis/shared.yml` |
| `AWS_ACCESS_KEY_ID` | `AWS_ACCESS_KEY_ID` | `aws_access_key_id` | `admin` | `storage.yml` |
| `AWS_SECRET_ACCESS_KEY` | `AWS_SECRET_ACCESS_KEY` | `aws_secret_access_key` | `password` | `storage.yml` |
| `AWS_ENDPOINT_URL` | `AWS_ENDPOINT_URL` | `aws_endpoint` (override) | `http://10.88.0.2:9000` | `storage.yml` |
| `OTEL_SERVICE_NAME` | `OTEL_SERVICE_NAME` | `otel_service_name` | `skyceer-#{Rails.env}` | `opentelemetry.rb` |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | `otel_exporter_otlp_traces_endpoint` | `http://localhost:5080/api/default/v1/traces` | `opentelemetry.rb` |
| `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT` | `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT` | `otel_exporter_otlp_logs_endpoint` | `http://localhost:5080/api/default/v1/logs` | `opentelemetry.rb` |
| `OTEL_EXPORTER_OTLP_HEADERS` | `OTEL_EXPORTER_OTLP_HEADERS` | `otel_exporter_otlp_headers` | `Authorization=Basic YWRtaW5AZXhhbXBsZS5jb206UGFzc3dvcmRAMTIz,organization=default` | `opentelemetry.rb` |
| `MISSION_CONTROL_USER` | `MISSION_CONTROL_USER` | `mission_control_user` | `dev` | `mission_control.rb` |
| `MISSION_CONTROL_PASSWORD` | `MISSION_CONTROL_PASSWORD` | `mission_control_password` | `secret` | `mission_control.rb` |
| `TEST_ENV_NUMBER` | `TEST_ENV_NUMBER` | `test_env_number` | `""` | `meilisearch.rb`, `redis/shared.yml`, `spec/retry_helper.rb` |
| `TEST_RUN_INSIDE_DOCKER` | `TEST_RUN_INSIDE_DOCKER` | `test_run_inside_docker` | `false` | `spec/selenium_helper.rb` |
| `SKIP_DB_SEED` | `SKIP_DB_SEED` | `skip_test_run_seed` | `false` | `db/seeds.rb` |

### 5.2 Inline-only (cannot or must not use constants)

| ENV | File | Rule |
|---|---|---|
| `POSTGRES_USERNAME` | `config/database.yml` | ENV → credentials `postgres_username` → `postgres` |
| `POSTGRES_PASSWORD` | `config/database.yml` | ENV → credentials `postgres_password` → `password` |
| `POSTGRES_HOST` | `config/database.yml` | ENV → credentials `postgres_host` → `localhost` |
| `POSTGRES_PORT` | `config/database.yml` | ENV → credentials `postgres_port` → `5432` |
| `RAILS_MAX_THREADS` | `config/database.yml` pool | ENV → `5` |
| `TEST_ENV_NUMBER` | `config/database.yml` | ENV only (test DB suffix) |
| `RAILS_LOG_LEVEL` | `config/environments/production.rb` | ENV → `info` |
| `RAILS_LOG_TO_STDOUT` | `config/environments/development.rb` | ENV only |
| `CI` | `config/environments/test.rb` | ENV only |
| `RAILS_MAX_THREADS` | `config/puma.rb` | ENV → `3` |
| `PORT` | `config/puma.rb` | ENV → `3000` |
| `PIDFILE` | `config/puma.rb` | ENV only |
| `SOLID_QUEUE_IN_PUMA` | `config/puma.rb` | ENV only |
| `BUNDLE_GEMFILE` | `config/boot.rb`, `bin/kamal` | framework |
| `RAILS_ENV` | `spec/rails_helper.rb` | spec bootstrap |
| `RAILS_MASTER_KEY`, `SECRET_KEY_BASE`, `DATABASE_URL`, `SOLID_CACHE_CONFIG`, other `OTEL_*` | framework / gems | owned by Rails or a gem |

### 5.3 Out of scope

- `mock_api/main.go` (Go dev server, own port).
- `android/` (`BuildConfig.BASE_URL` from Gradle `-PskycomBaseUrl`).
- `.kamal/*`, `docker-compose*.yml`, `Dockerfile`, `Procfile.dev`, `.github/workflows/*` — these
  set ENV for containers; they are not readers.

---

## 6. Shared helpers

None. The declarations are plain expressions in `config/initializers/constants.rb`.
This is deliberate: the repo owner rejected a resolver module.

Load-order note: `config/initializers/constants.rb` loads after `assets.rb` and `cache.rb`
(alphabetical). Do not read env constants from files sorting before it.

---

## 7. Implementation steps

### Step 1 — Plan + spec (RED)

1. Add this plan file.
2. Add `spec/initializers/environment_configuration_spec.rb`:
   - ENV wins for `MEILISEARCH_HOST` (subprocess boot).
   - ENV wins and coerces for `JOB_CONCURRENCY` (subprocess boot → Integer).
   - `TEST_RUN_INSIDE_DOCKER=false` resolves false (subprocess boot).
   - default is used when the ENV var is unset (subprocess boot).
   - every catalog constant is defined.
   - `bin/check_env` exits 0.
3. Run it; expect RED (`NameError: uninitialized constant MEILISEARCH_HOST`).
4. Add `spec/initializers` to the CI rspec path list.

### Step 2 — Declarations (GREEN)

1. Add the env section at the top of `config/initializers/constants.rb` (plain assignments + warning block).
2. Replace the existing `WEBHOOK_*` lines.
3. Run the spec; expect GREEN.

### Step 3 — Initializers

1. `meilisearch.rb` → `MEILISEARCH_HOST`, `MEILISEARCH_API_KEY`, `TEST_ENV_NUMBER`.
2. `websocket.rb` → 3 constants.
3. `omniauth.rb` → `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`.
4. `opentelemetry.rb` → 4 constants; bridge constants into ENV for the SDK (documented exception).
5. `mission_control.rb` → `MISSION_CONTROL_USER`, `MISSION_CONTROL_PASSWORD`.

### Step 4 — Services

1. `mock_qr_gateway.rb` → `MOCK_QR_GATEWAY_URL`, `MOCK_QR_WEBHOOK_URL`.
2. `mock_redirect_gateway.rb` → `MOCK_REDIRECT_GATEWAY_URL`, `MOCK_REDIRECT_WEBHOOK_URL`.

### Step 5 — YAML

1. `storage.yml` → `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL`.
2. `redis/shared.yml` → `REDIS_URL_*` + `TEST_ENV_NUMBER` for the per-worker DB path.
3. `queue.yml` → `JOB_CONCURRENCY`.
4. `database.yml` → inline ENV precedence for `POSTGRES_*`; `pool` from `RAILS_MAX_THREADS`.

### Step 6 — Seeds, specs, compose

1. `db/seeds.rb` → `return if SKIP_DB_SEED`.
2. `spec/retry_helper.rb` → `TEST_ENV_NUMBER`.
3. `spec/selenium_helper.rb` → `TEST_RUN_INSIDE_DOCKER`.
4. `spec/system/mock_api_connection_spec.rb` → use the global `MOCK_API_PING_URL`.
5. `docker-compose.rspec-test.yml` → `SKIP_DB_SEED: true`.

### Step 7 — Guardrail

1. Add `bin/check_env` (Ruby, allowlist, exits 1 on findings).
2. Add it to the CI lint job.
3. Add it to `AGENTS.md` quick commands + pre-commit checklist.

### Step 8 — Docs

1. New `docs/ENVIRONMENT.md`: rule, declaration pattern, catalog, exceptions, warning, how to add,
   verification, out-of-scope list.
2. `docs/CONSTANTS.md`: link + env-backed row + single-file exception note.
3. `AGENTS.md`: doc-map row.
4. Refresh changed snippets: `docs/CACHE.md` (redis), `docs/MEILISEARCH.md` (table),
   `docs/WEBSOCKET.md` (note), `docs/IMMUTABLE_OS_SETUP.md` (file reference), `COMMANDS.md`.

### Step 9 — Verification

Run every command in §10.

---

## 8. Tests

### Feature specs (primary proof)

- None: no UI change. Config regression proof is the boot-level spec + targeted request specs.

### Config spec

- ENV precedence (representative secret, integer, boolean).
- Default fallback when ENV is unset.
- Catalog completeness (all 30 constants defined).
- `bin/check_env` clean.

### Request specs (regression)

- `spec/requests/webhooks/payments/` — the webhook secrets are still resolvable.
- `spec/requests/companies/top_ups_controller_spec.rb` — mock gateway constants.
- `spec/requests/companies/order_processing/v1_controller_spec.rb` — mock gateway constants.

---

## 9. Documentation

- `docs/ENVIRONMENT.md` — new canonical doc.
- `docs/CONSTANTS.md` — pointer + scope rules.
- `AGENTS.md` — doc map + pre-commit + quick command.
- `docs/CACHE.md`, `docs/MEILISEARCH.md`, `docs/WEBSOCKET.md`, `docs/IMMUTABLE_OS_SETUP.md`, `COMMANDS.md` — refresh changed snippets.

No `docs/MODEL_CALLBACKS.md` change (no callbacks). No dictionary entries (no user-facing strings).

---

## 10. Verification

```bash
bin/check_env
bundle exec parallel_rspec -n 14 spec/initializers/environment_configuration_spec.rb
bundle exec parallel_rspec -n 14 spec/requests/webhooks/payments/ spec/requests/companies/top_ups_controller_spec.rb spec/requests/companies/order_processing/v1_controller_spec.rb
bin/rubocop
bin/brakeman --no-pager
bin/check_colors --strict
```

Boot smoke:

```bash
bin/rails runner 'Rails.application.config_for("redis/shared"); Rails.application.config_for(:queue); ActiveStorage::Blob.service; puts [MEILISEARCH_HOST, CENTRIFUGO_ENDPOINT, REDIS_URL_DEVELOPMENT, AWS_ENDPOINT_URL, JOB_CONCURRENCY].inspect'
```

Manual smoke:

1. `bin/rails runner 'puts MEILISEARCH_HOST'` → default.
2. `MEILISEARCH_HOST=http://env.test bin/rails runner 'puts MEILISEARCH_HOST'` → `http://env.test`.
3. `TEST_RUN_INSIDE_DOCKER=false bin/rails runner 'p TEST_RUN_INSIDE_DOCKER'` → `false`.
4. `bin/check_env` → exit 0.

---

## 11. Risks / notes

- **Credentials file unavailable locally** (`config/master.key` absent): credential-branch values are nil
  locally; the ENV and default branches are exercised by the spec. All existing credential key names are
  preserved, so production is unaffected once the key is present.
- **`ENV.presence` semantics**: blank ENV values fall through to credentials/default. This is a small
  behaviour change from plain `||` in `meilisearch.rb` / `websocket.rb`, and it is the intended one.
- **Boolean strictness**: `"false"` now means false. `SKIP_DB_SEED: false` in the rspec compose file
  was already skipping seeds only because the string was truthy; the compose value is corrected to `true`.
- **Lazy YAML constant resolution**: verified that `ActiveSupport::ConfigurationFile.parse` resolves
  top-level constants. Storage/Redis/Queue config is parsed after initializers; if a future load-order
  change breaks it, fall back to the inline pattern for that file (document it).
- **`config/initializers/constants.rb` load order**: files sorting before it (`assets.rb`, `cache.rb`) must
  not read these constants.
- **Production warning covers constants only**; the Postgres password in `database.yml` is documented in
  the production checklist instead.
- **No new user-facing strings**; no cache keys changed.

---

## 12. Out of scope

- No behaviour change to payment gateways, websockets, Meilisearch, storage, or Mission Control beyond
  configuration sourcing.
- No renaming of existing ENV variables or credential keys.
- No change to `mock_api/main.go`, `android/`, Kamal, compose, Dockerfile, or CI env values (except the
  `SKIP_DB_SEED` correction).
- No new hosting/secret-manager integration.

---

## 13. Definition of done

- [x] Every Ruby ENV read lives in `config/initializers/constants.rb` or an allowlisted pre-boot file.
- [x] Every catalog constant is a plain `ENV || credentials || default` declaration.
- [x] Consumers use only constants.
- [x] `bin/check_env` exists, passes, and runs in CI.
- [x] `docs/ENVIRONMENT.md` documents the rule, catalog, exceptions, and how to add a variable.
- [x] `AGENTS.md` and `docs/CONSTANTS.md` point to it.
- [x] Config spec green; targeted request specs green.
- [x] `bin/rubocop`, `bin/brakeman`, `bin/check_colors --strict` clean.
