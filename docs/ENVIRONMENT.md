# Environment & Credentials Convention

Every environment-backed value in Skycom has **one declaration** and **one precedence rule**.

## 1. The rule

```text
ENV["VARIABLE"].presence  >  Rails.application.credentials.dig(:variable)  >  hardcoded default
```

1. **ENV** — checked first so any environment can be overridden from the shell, a container,
   Kamal, or CI without re-encrypting credentials.
2. **Credentials** — the durable secret store (`bin/rails credentials:edit`).
3. **Default** — keeps development and test bootable with zero setup.

A blank ENV value counts as unset, so `MEILISEARCH_HOST=` falls through to credentials/default.
Never put the same value in two places.

## 2. Where declarations live

All ENV reads happen in `config/initializers/constants.rb`, in the
`Environment-backed configuration` section. Every other Ruby file — initializer, service, model,
controller, job, seed, spec — uses the constant.

```ruby
# config/initializers/constants.rb
MEILISEARCH_HOST = ENV["MEILISEARCH_HOST"].presence ||
  Rails.application.credentials.dig(:meilisearch_host) ||
  "http://localhost:7700"
```

- **Constant name = ENV name.** `MEILISEARCH_HOST` ↔ `ENV["MEILISEARCH_HOST"]`.
  Grep either way and you land on the same concept.
- **Credential key = ENV name downcased symbol.** `MEILISEARCH_HOST` → `:meilisearch_host`.
  The encrypted file already uses this shape, so no mapping table exists.
- **One exception:** `AWS_ENDPOINT_URL` reads `:aws_endpoint` (the legacy credential key).
- Typed values coerce at declaration:

```ruby
JOB_CONCURRENCY = (ENV["JOB_CONCURRENCY"].presence ||
  Rails.application.credentials.dig(:job_concurrency) || 1).to_i

TEST_RUN_INSIDE_DOCKER = ActiveModel::Type::Boolean.new.cast(
  ENV["TEST_RUN_INSIDE_DOCKER"].presence ||
    Rails.application.credentials.dig(:test_run_inside_docker) || false
)
```

`ActiveModel::Type::Boolean` treats `"false"`, `"0"`, `"no"`, `"off"` as false — use it for flags.

### Consumers

```ruby
# config/initializers/meilisearch.rb
Meilisearch::Rails.configuration = {
  meilisearch_url: MEILISEARCH_HOST,
  meilisearch_api_key: MEILISEARCH_API_KEY,
  per_environment: true
}

# app/services/payments/mock_qr_gateway.rb
conn = Faraday.new(url: MOCK_QR_GATEWAY_URL)

# config/queue.yml
processes: <%= JOB_CONCURRENCY %>

# config/redis/shared.yml
development:
  url: <%= REDIS_URL_DEVELOPMENT %>
```

## 3. Catalog

### 3.1 Declared in `config/initializers/constants.rb`

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
| `WEBHOOK_BANK_PAYMENT_SECRET` | `WEBHOOK_BANK_PAYMENT_SECRET` | `webhook_bank_payment_secret` | `local_secure_dev_secret` | `Webhooks::Payments::*Controller` |
| `WEBHOOK_REDIRECT_PAYMENT_SECRET` | `WEBHOOK_REDIRECT_PAYMENT_SECRET` | `webhook_redirect_payment_secret` | `local_secure_dev_secret` | `Webhooks::Payments::*Controller` |
| `JOB_CONCURRENCY` | `JOB_CONCURRENCY` | `job_concurrency` | `1` | `config/queue.yml` |
| `REDIS_URL_PRODUCTION` | `REDIS_URL_PRODUCTION` | `redis_url_production` | `redis://127.0.0.1:6379/0` | `config/redis/shared.yml` |
| `REDIS_URL_DEVELOPMENT` | `REDIS_URL_DEVELOPMENT` | `redis_url_development` | `redis://127.0.0.1:6379/0` | `config/redis/shared.yml` |
| `REDIS_URL_TEST` | `REDIS_URL_TEST` | `redis_url_test` | `redis://127.0.0.1:6379/0` | `config/redis/shared.yml` |
| `AWS_ACCESS_KEY_ID` | `AWS_ACCESS_KEY_ID` | `aws_access_key_id` | `admin` | `config/storage.yml` |
| `AWS_SECRET_ACCESS_KEY` | `AWS_SECRET_ACCESS_KEY` | `aws_secret_access_key` | `password` | `config/storage.yml` |
| `AWS_ENDPOINT_URL` | `AWS_ENDPOINT_URL` | `aws_endpoint` | `http://10.88.0.2:9000` | `config/storage.yml` |
| `OTEL_SERVICE_NAME` | `OTEL_SERVICE_NAME` | `otel_service_name` | `skyceer-<env>` | `opentelemetry.rb` |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | `otel_exporter_otlp_traces_endpoint` | `http://localhost:5080/api/default/v1/traces` | `opentelemetry.rb` |
| `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT` | `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT` | `otel_exporter_otlp_logs_endpoint` | `http://localhost:5080/api/default/v1/logs` | `opentelemetry.rb` |
| `OTEL_EXPORTER_OTLP_HEADERS` | `OTEL_EXPORTER_OTLP_HEADERS` | `otel_exporter_otlp_headers` | `Authorization=Basic …,organization=default` | `opentelemetry.rb` |
| `MISSION_CONTROL_USER` | `MISSION_CONTROL_USER` | `mission_control_user` | `dev` | `mission_control.rb` |
| `MISSION_CONTROL_PASSWORD` | `MISSION_CONTROL_PASSWORD` | `mission_control_password` | `secret` | `mission_control.rb` |
| `TEST_ENV_NUMBER` | `TEST_ENV_NUMBER` | `test_env_number` | `""` | `meilisearch.rb`, `config/redis/shared.yml`, `spec/retry_helper.rb` |
| `TEST_RUN_INSIDE_DOCKER` | `TEST_RUN_INSIDE_DOCKER` | `test_run_inside_docker` | `false` | `spec/selenium_helper.rb` |
| `SKIP_DB_SEED` | `SKIP_DB_SEED` | `skip_db_seed` | `false` | `db/seeds.rb` |

`SKIP_DB_SEED=true` skips the seed that `db:prepare` runs on a freshly created
database. The rspec container sets it; the seed-test pipeline leaves it unset so
seeding is exercised.

### 3.2 Inline-only (documented exceptions)

These files are evaluated before `config/initializers/constants.rb`, outside the initializer
sequence, or by a gem that owns the variable. They repeat the same `ENV → credentials → default`
rule inline; do not add new ones without a comment and a `bin/check_env` allowlist entry.

| ENV | File | Rule |
|---|---|---|
| `POSTGRES_USERNAME` | `config/database.yml` | ENV → `postgres_username` → `postgres` |
| `POSTGRES_PASSWORD` | `config/database.yml` | ENV → `postgres_password` → `password` |
| `POSTGRES_HOST` | `config/database.yml` | ENV → `postgres_host` → `localhost` |
| `POSTGRES_PORT` | `config/database.yml` | ENV → `postgres_port` → `5432` |
| `RAILS_MAX_THREADS` | `config/database.yml` (pool) | ENV → `5` |
| `TEST_ENV_NUMBER` | `config/database.yml` (test DB suffix) | ENV only |
| `RAILS_LOG_LEVEL` | `config/environments/production.rb` | ENV → `info` |
| `RAILS_LOG_TO_STDOUT` | `config/environments/development.rb` | ENV only |
| `CI` | `config/environments/test.rb` | ENV only |
| `RAILS_MAX_THREADS` | `config/puma.rb` | ENV → `3` |
| `PORT` | `config/puma.rb` | ENV → `3000` |
| `PIDFILE` | `config/puma.rb` | ENV only |
| `SOLID_QUEUE_IN_PUMA` | `config/puma.rb` | ENV only |
| `BUNDLE_GEMFILE` | `config/boot.rb`, `bin/kamal` | framework |
| `RAILS_ENV` | `spec/rails_helper.rb` | spec bootstrap |

Framework/gem-owned variables are configured with their standard names and are not redeclared:
`RAILS_MASTER_KEY`, `SECRET_KEY_BASE`, `SECRET_KEY_BASE_DUMMY`, `DATABASE_URL` (Rails merges it over
`database.yml`), `SOLID_CACHE_CONFIG`, and the OTel SDK knobs not listed in §3.1.

### 3.3 Out of scope

- `mock_api/main.go` — Go dev server with its own port.
- `android/` — `BuildConfig.BASE_URL` comes from the Gradle property `-PskycomBaseUrl`.
- `docker-compose*.yml`, `Dockerfile`, `Procfile.dev`, `config/deploy.yml`, `.kamal/secrets`,
  `.github/workflows/*` — these **set** ENV for containers/jobs; they are not readers.

## 4. Production warning

`constants.rb` warns once at boot in production when a secret with a compiled-in dev default is
unset. It checks ENV and credentials only:

```text
[env] MEILISEARCH_API_KEY is unset; using its compiled-in development default.
```

Secrets covered: `MEILISEARCH_API_KEY`, `CENTRIFUGO_API_KEY`, `CENTRIFUGO_TOKEN_HMAC_SECRET_KEY`,
`WEBHOOK_BANK_PAYMENT_SECRET`, `WEBHOOK_REDIRECT_PAYMENT_SECRET`, `AWS_SECRET_ACCESS_KEY`,
`MISSION_CONTROL_PASSWORD`, `OTEL_EXPORTER_OTLP_HEADERS`.

The Postgres password lives in `database.yml` (inline exception) and is not covered — set
`DATABASE_URL` or `POSTGRES_PASSWORD` in production.

## 5. Third-party SDK bridge

`config/initializers/opentelemetry.rb` writes the resolved `OTEL_EXPORTER_OTLP_*` constants into
ENV because the OTel SDK reads ENV directly. The constant remains the source of truth; this is the
only allowed ENV write outside `constants.rb`.

## 6. Load order

`config/initializers/*.rb` load alphabetically. `constants.rb` loads after `assets.rb` and
`cache.rb`; those two must not read env constants. All other initializers (`meilisearch.rb`,
`omniauth.rb`, `opentelemetry.rb`, `websocket.rb`, `mission_control.rb`) load after it.

Lazily parsed YAML (`config/storage.yml`, `config/redis/shared.yml`, `config/queue.yml`) is read
after initialization, so it resolves the constants. `config/database.yml` is deliberately inline.

## 7. Adding a new environment variable

1. Declare it in the `Environment-backed configuration` section of
   `config/initializers/constants.rb`:

   ```ruby
   NEW_THING_URL = ENV["NEW_THING_URL"].presence ||
     Rails.application.credentials.dig(:new_thing_url) ||
     "http://localhost:1234"
   ```

2. Use the constant everywhere. No `ENV` reads in app code.
3. If it can only be read from an early/lazy file, add it to the inline table in §3.2 and to the
   `bin/check_env` allowlist with a comment.
4. If it is a secret with a dev default, add it to the production warning hash.
5. Add it to the catalog table above.
6. Run `bin/check_env`, `bin/rubocop`, and `bundle exec parallel_rspec -n 14 spec/initializers/environment_configuration_spec.rb`.

## 8. Verification

```bash
bin/check_env
bundle exec parallel_rspec -n 14 spec/initializers/environment_configuration_spec.rb
```

The spec boots Rails in a subprocess and proves ENV precedence, default fallback, integer and
boolean coercion, catalog completeness, and that the guard passes.

Manual smoke:

```bash
bin/rails runner 'puts MEILISEARCH_HOST'                                  # default
MEILISEARCH_HOST=http://env.test bin/rails runner 'puts MEILISEARCH_HOST' # ENV wins
bin/rails runner 'p Rails.application.config_for("redis/shared")'         # YAML constant
ActiveStorage::Blob.service.class                                         # S3 from storage.yml
```

## 9. File reference

| File | Role |
|---|---|
| `config/initializers/constants.rb` | The one declaration panel |
| `config/initializers/meilisearch.rb` | Consumes Meilisearch constants |
| `config/initializers/websocket.rb` | Consumes Centrifugo constants |
| `config/initializers/omniauth.rb` | Consumes Google OAuth constants |
| `config/initializers/opentelemetry.rb` | Consumes OTel constants; ENV bridge |
| `config/initializers/mission_control.rb` | Consumes Mission Control constants |
| `app/services/payments/mock_qr_gateway.rb` | Consumes mock QR URLs |
| `app/services/payments/mock_redirect_gateway.rb` | Consumes mock redirect URLs |
| `config/storage.yml` | S3/RustFS from constants |
| `config/redis/shared.yml` | Redis URLs from constants |
| `config/queue.yml` | Solid Queue concurrency from the constant |
| `config/database.yml` | Inline Postgres ENV precedence |
| `bin/check_env` | Guard: raw ENV reads outside the allowlist fail |
| `spec/initializers/environment_configuration_spec.rb` | Precedence + catalog proof |
