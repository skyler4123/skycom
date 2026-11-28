# Observability (Lograge + OpenTelemetry)

> **Status: removed on 2026-11-28** in `refactor: remove lograge and opentelemetry`.
> Skycom does not ship Lograge or OpenTelemetry today. This file is the restore
> recipe: it holds verbatim copies of everything that was deleted and the order
> to put it back.
>
> After restoring, delete this file (or flip its status) and update
> `docs/ENVIRONMENT.md` in the same commit.

## 1. What was removed

| Area | File | What |
|---|---|---|
| Gems | `Gemfile`, `Gemfile.lock` | `lograge` + six `opentelemetry-*` gems |
| Traces/logs | `config/initializers/opentelemetry.rb` | OTLP traces + logs SDK setup, instrumentation list |
| Tenant attribute | `app/middleware/opentelemetry_tenant_middleware.rb` | `company_id` span attribute |
| Middleware hook | `config/application.rb` | `require_relative` + `insert_before 0` |
| Dev request logs | `config/environments/development.rb` | Lograge JSON formatter + trace/span ids |
| Constants | `config/initializers/constants.rb` | `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_*` |
| Env guard | `bin/check_env` | allowlist entry for the initializer |
| Env spec | `spec/initializers/environment_configuration_spec.rb` | four catalog names |
| Local backend | `docker-compose.yml` | `openobserve` service + `openobserve_data` volume |
| Docs | `docs/ENVIRONMENT.md`, `docs/IMMUTABLE_OS_SETUP.md` | catalog rows, bridge section, service rows |

Nothing else in `app/`, `lib/`, `config/`, `spec/`, `.github/`, or `.kamal/`
referenced Lograge or OpenTelemetry.

## 2. One-shot restore

If the removal commit is still reachable in your history:

```bash
git log --grep='remove lograge and opentelemetry' --oneline
git revert <sha>          # restores every hunk below in one commit
bundle install
```

`git revert` also restores the OpenObserve compose service. Use §3 when the
commit is too old to revert cleanly or you only want part of the stack.

## 3. Manual restore

Restore in this order.

### 3.1 Gems

Add to `Gemfile` (after `gem "kredis"`, before `gem "cent"`):

```ruby
gem "opentelemetry-sdk"
gem "opentelemetry-exporter-otlp"
gem "opentelemetry-logs-sdk"
gem "opentelemetry-exporter-otlp-logs"
gem "opentelemetry-instrumentation-all"
gem "opentelemetry-instrumentation-logger"
gem "lograge"
```

Then:

```bash
bundle install
```

Versions at removal time (matching them is not required; resolve fresh):

| Gem | Version |
|---|---|
| `lograge` | 0.15.1 |
| `opentelemetry-sdk` | 1.13.1 |
| `opentelemetry-exporter-otlp` | 0.37.0 |
| `opentelemetry-logs-sdk` | 0.7.0 |
| `opentelemetry-exporter-otlp-logs` | 0.6.0 |
| `opentelemetry-instrumentation-all` | 0.97.0 |
| `opentelemetry-instrumentation-logger` | 0.4.0 |

### 3.2 Constants

In `config/initializers/constants.rb`, after `AWS_ENDPOINT_URL` and before
`# --- Mission Control (jobs dashboard) ---`:

```ruby
# --- OpenTelemetry ---
OTEL_SERVICE_NAME = ENV["OTEL_SERVICE_NAME"].presence ||
  Rails.application.credentials.dig(:otel_service_name) ||
  "skyceer-#{Rails.env}"

OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = ENV["OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"].presence ||
  Rails.application.credentials.dig(:otel_exporter_otlp_traces_endpoint) ||
  "http://localhost:5080/api/default/v1/traces"

OTEL_EXPORTER_OTLP_LOGS_ENDPOINT = ENV["OTEL_EXPORTER_OTLP_LOGS_ENDPOINT"].presence ||
  Rails.application.credentials.dig(:otel_exporter_otlp_logs_endpoint) ||
  "http://localhost:5080/api/default/v1/logs"

OTEL_EXPORTER_OTLP_HEADERS = ENV["OTEL_EXPORTER_OTLP_HEADERS"].presence ||
  Rails.application.credentials.dig(:otel_exporter_otlp_headers) ||
  "Authorization=Basic YWRtaW5AZXhhbXBsZS5jb206UGFzc3dvcmRAMTIz,organization=default"
```

Also add the secret to the production warning hash in the same file:

```ruby
"MISSION_CONTROL_PASSWORD" => :mission_control_password,
"OTEL_EXPORTER_OTLP_HEADERS" => :otel_exporter_otlp_headers
```

Environment precedence stays `ENV > credentials > default`; the credential keys
are `:otel_service_name`, `:otel_exporter_otlp_traces_endpoint`,
`:otel_exporter_otlp_logs_endpoint`, and `:otel_exporter_otlp_headers`. They may
still exist in the encrypted credentials; they are harmless while unused.

### 3.3 OTLP initializer

Create `config/initializers/opentelemetry.rb`:

```ruby
# config/initializers/opentelemetry.rb

return if Rails.env.test?

require "opentelemetry/sdk"
require "opentelemetry/instrumentation/rails"
require "opentelemetry-logs-sdk"
require "opentelemetry/exporter/otlp_logs"
require "opentelemetry/instrumentation/logger"

# 1. The OTel SDK reads OTEL_* from ENV itself, so publish the resolved
# constants (ENV > credentials > default) into ENV. This file is the documented
# bridge; see docs/ENVIRONMENT.md.
ENV["OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"] = OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
ENV["OTEL_EXPORTER_OTLP_LOGS_ENDPOINT"]   = OTEL_EXPORTER_OTLP_LOGS_ENDPOINT
ENV["OTEL_EXPORTER_OTLP_HEADERS"]         = OTEL_EXPORTER_OTLP_HEADERS

# 2. Configure Traces & general instrumentation
OpenTelemetry::SDK.configure do |c|
  c.service_name = OTEL_SERVICE_NAME

  c.use_all(
    "OpenTelemetry::Instrumentation::Net::HTTP" => {
      untraced_hosts: [ "localhost" ]
    },
    "OpenTelemetry::Instrumentation::ActiveRecord" => { enabled: false },
    "OpenTelemetry::Instrumentation::Rake"         => { enabled: false },
    "OpenTelemetry::Instrumentation::PG"           => { enabled: false },
    "OpenTelemetry::Instrumentation::ActionView"   => { enabled: false },
    "OpenTelemetry::Instrumentation::ActiveStorage"=> { enabled: false },
    "OpenTelemetry::Instrumentation::ConcurrentRuby" => { enabled: false },
    "OpenTelemetry::Instrumentation::Faraday"      => { enabled: false },
    "OpenTelemetry::Instrumentation::Mongo"        => { enabled: false },
    "OpenTelemetry::Instrumentation::Rails"        => { enabled: false },
    "OpenTelemetry::Instrumentation::Redis"        => { enabled: false },
  )
end

# 3. Configure the Logs SDK using the proper SDK namespaces
logger_provider = OpenTelemetry::SDK::Logs::LoggerProvider.new
processor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(
  OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new
)
logger_provider.add_log_record_processor(processor)

# Set the global logger provider for the application
OpenTelemetry.logger_provider = logger_provider
```

Notes:

- `return if Rails.env.test?` keeps the spec suite from exporting spans.
- The SDK reads `OTEL_*` from ENV directly, so the initializer publishes the
  resolved constants. This is the only allowed ENV write outside
  `constants.rb`; add the file to the `bin/check_env` allowlist (§3.7).
- The disabled instrumentation list is deliberate: Rails, ActiveRecord, PG,
  Redis, and friends were turned off to avoid duplicate spans and boot cost.
  `Net::HTTP` ignores `localhost` so webhook traffic is not traced.

### 3.4 Tenant middleware

Create `app/middleware/opentelemetry_tenant_middleware.rb`:

```ruby
# app/middleware/opentelemetry_tenant_middleware.rb
class OpentelemetryTenantMiddleware
  COMPANIES_PATH_REGEX = %r{\A/companies/([^/?]+)}

  def initialize(app)
    @app = app
  end

  def call(env)
    if (match = env["PATH_INFO"]&.match(COMPANIES_PATH_REGEX))
      company_id = match[1]
    else
      company_id = "public"
    end

    current_span = OpenTelemetry::Trace.current_span
    # If this evaluates to false, it means OpenTelemetry Rack instrumentation is completely turned off
    if current_span.recording?
      current_span.set_attribute("company_id", company_id)
    else
      # Fallback log warning to your local Rails console if the span isn't tracking yet
      Rails.logger.warn "OpenTelemetry: No active recording span found for path #{env['PATH_INFO']}"
    end

    @app.call(env)
  end
end
```

Then in `config/application.rb`, above `module Skycom`:

```ruby
require_relative "../app/middleware/opentelemetry_tenant_middleware"
```

and inside `class Application` (after `config.generators.orm`):

```ruby
config.middleware.insert_before 0, OpentelemetryTenantMiddleware
```

### 3.5 Development Lograge config

In `config/environments/development.rb`, after the Solid Queue block and before
`config.log_level = :info`:

```ruby
# 1. Enable Lograge
config.lograge.enabled = true
config.lograge.formatter = Lograge::Formatters::Json.new

# 2. FIX: Ignore ActiveStorage controller routes completely
config.lograge.ignore_actions = [
  "ActiveStorage::Representations::RedirectController#show",
  "ActiveStorage::Blobs::RedirectController#show",
  "ActiveStorage::DiskController#show"
]

# Alternatively, you can catch any custom assets/storage routes by path matching:
# config.lograge.ignore_custom = lambda do |event|
#   event.payload[:path]&.start_with?("/rails/active_storage")
# end

# 3. Add your custom metadata options
config.lograge.custom_options = lambda do |event|
  current_span = OpenTelemetry::Trace.current_span
  {
    environment: Rails.env.to_s,
    time: Time.current.iso8601,
    trace_id: current_span.context.valid? ? current_span.context.hex_trace_id : nil,
    span_id: current_span.context.valid? ? current_span.context.hex_span_id : nil
  }
end
```

### 3.6 Env spec

In `spec/initializers/environment_configuration_spec.rb`, add back to `CATALOG`
after the AWS line:

```ruby
OTEL_SERVICE_NAME
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT OTEL_EXPORTER_OTLP_LOGS_ENDPOINT OTEL_EXPORTER_OTLP_HEADERS
```

### 3.7 Env guard

In `bin/check_env`, add to `ALLOWLIST` after `config/initializers/constants.rb`:

```ruby
config/initializers/opentelemetry.rb
```

### 3.8 OpenObserve (local backend)

In `docker-compose.yml`, add the service (before `websocket`) and the
`openobserve_data` volume:

```yaml
  openobserve:
    image: openobserve/openobserve:latest
    environment:
      - ZO_DATA_DIR=/data
      - ZO_ROOT_USER_EMAIL=admin@example.com
      - ZO_ROOT_USER_PASSWORD=Password@123
    ports:
      - "5080:5080" # UI and OTel endpoint
    volumes:
      - openobserve_data:/data
```

Add `openobserve` back to the header command:

```bash
docker compose up -d postgres redis stograge websocket meilisearch mock-api openobserve
```

Then:

```bash
docker compose up -d openobserve
```

Open <http://localhost:5080> — `admin@example.com` / `Password@123`. The
`OTEL_EXPORTER_OTLP_HEADERS` default is the Basic auth pair for those
credentials plus `organization=default`. Rotate both outside development.

### 3.9 Docs

- `docs/ENVIRONMENT.md`: re-add the four OTEL rows to §3.1, delete §3.4
  ("Removed integrations"), restore the §5 "Third-party SDK bridge" section
  (renumbering the current §5–§8 → §6–§9), the production-warning secret, the
  load-order mention, and the file-reference row.
- `docs/IMMUTABLE_OS_SETUP.md`: re-add the OpenObserve row to the service table
  and the browser check.
- `AGENTS.md`: the doc-map row can stay; it points here.

## 4. Verify

```bash
bundle check
bin/rails runner 'p defined?(OpenTelemetry); p defined?(Lograge)'   # "constant", "constant"
bin/rails runner 'p Rails.application.middleware.map(&:name).grep(/Opentelemetry/)'
# => ["OpentelemetryTenantMiddleware"]
bin/check_env
bundle exec parallel_rspec -n 14 spec/initializers/environment_configuration_spec.rb
```

End-to-end:

1. `docker compose up -d openobserve`
2. `bin/dev`
3. Load a page, then open <http://localhost:5080> → Traces / Logs.
4. Open a `/companies/:id/...` page and confirm the span carries
   `company_id=<id>`; public pages carry `company_id=public`.

You should also see one JSON request line per request in the development log
with `environment`, `time`, `trace_id`, and `span_id`.

## 5. Partial restores

### 5.1 Lograge only (no OTel)

Do §3.1 and §3.5 only, and replace the custom options with:

```ruby
config.lograge.custom_options = lambda do |event|
  {
    environment: Rails.env.to_s,
    time: Time.current.iso8601
  }
end
```

Traces/logs are not exported; OpenObserve is unnecessary.

### 5.2 OTel only (no Lograge)

Do §3.1–§3.4 and §3.6–§3.8, skip `gem "lograge"`, and skip §3.5. Traces and
logs still flow to OpenObserve; Rails keeps its default development logging.

## 6. Gotchas

- **Test env is off by design** — the initializer returns before requiring the
  SDK, so feature specs never export spans and do not need a collector.
- **ENV bridge** — the OTel SDK reads `OTEL_EXPORTER_OTLP_*` from ENV, not from
  Rails constants. Without the bridge in §3.3 the endpoints silently fall back
  to SDK defaults and nothing reaches OpenObserve.
- **Middleware order** — `insert_before 0` is required so the tenant attribute
  is set while the Rack span is recording; otherwise `current_span.recording?`
  is false and the middleware logs a warning on every request.
- **ActiveStorage noise** — the `ignore_actions` list suppresses the redirect
  controllers; keep it or JSON logs fill with asset requests.
- **Logger target** — `RAILS_LOG_TO_STDOUT` / `rails server` decides stdout vs
  `log/development.log`; Lograge writes through the same logger.
- **Credentials** — the encrypted files may still contain the `otel_*` keys.
  They are harmless while unused; leave them for an easy restore or remove them
  with `bin/rails credentials:edit`.
- **OpenObserve volume** — removing the service does not delete
  `openobserve_data`. `docker volume rm skycom_development_openobserve_data`
  only if you want to discard old traces.
