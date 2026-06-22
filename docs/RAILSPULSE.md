# Skycom RailsPulse Performance Monitoring

## 1. Overview

Skycom uses **RailsPulse** (v0.3.2) — a Rails engine for application performance monitoring. It tracks HTTP requests, database queries, background jobs, and deployments, storing data in a dedicated PostgreSQL database.

RailsPulse is mounted at the `/rails_pulse` path alongside Mission Control Jobs.

---

## 2. Architecture

### Layer Diagram

```
Application Requests / Background Jobs
        │
        ▼
  RailsPulse Middleware / Subscriber hooks
        │
        ├── Captures: duration, SQL, controller action, status, errors
        │
        ▼
  Dedicated PostgreSQL Database (port 5433)
  ├── rails_pulse_requests       — HTTP request records
  ├── rails_pulse_routes         — Route definitions
  ├── rails_pulse_queries        — Normalized SQL queries
  ├── rails_pulse_operations     — Fine-grained operations (SQL, view render, cache)
  ├── rails_pulse_jobs           — Background job definitions
  ├── rails_pulse_job_runs       — Individual job executions
  ├── rails_pulse_deployments    — Deployment markers
  └── rails_pulse_summaries      — Aggregated performance stats (hourly/daily/weekly/monthly)
```

### Database Isolation

RailsPulse uses a **separate PostgreSQL instance** on port 5433 (main app on 5432) to isolate performance data from application data:

| Database | Engine | Port | Purpose |
|----------|--------|------|---------|
| `skycom_*` | PostgreSQL | 5432 | Application data |
| `skycom_pulse_*` | PostgreSQL | 5433 | Performance monitoring data |

---

## 3. File Reference

| File | Purpose |
|------|---------|
| `Gemfile:96` | `gem "rails_pulse"` declaration |
| `config/initializers/rails_pulse.rb` | Full configuration (287 lines) |
| `config/routes.rb:76` | `mount RailsPulse::Engine => "/rails_pulse"` |
| `config/database.yml:127-190` | Database config per environment |
| `db/rails_pulse_schema.rb` | Auto-generated schema (7 tables) |

---

## 4. Configuration Reference

### Global Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `enabled` | `true` | Enable/disable RailsPulse |
| `track_assets` | `false` | Skip asset pipeline requests |
| `track_jobs` | `false` | Background job tracking disabled |
| `capture_job_arguments` | `true` | Capture job payload (dev only) |
| `archiving_enabled` | `true` | Auto-cleanup old data |
| `full_retention_period` | `2.weeks` | Data retention window |
| `tags` | `["ignored", "critical", "experimental"]` | Route/request categorization tags |

### Thresholds (milliseconds)

| Type | Slow | Very Slow | Critical |
|------|------|-----------|----------|
| Route | 500ms | 1500ms | 3000ms |
| Request | 700ms | 2000ms | 4000ms |
| Query | 100ms | 500ms | 1000ms |
| Job | 5s | 30s | 60s |

### Data Retention Limits

| Table | Max Records |
|-------|-------------|
| `rails_pulse_requests` | 10,000 |
| `rails_pulse_operations` | 50,000 |
| `rails_pulse_routes` | 1,000 |
| `rails_pulse_queries` | 500 |

### Database Connection

```ruby
config.connects_to = {
  database: { writing: :rails_pulse, reading: :rails_pulse }
}
```

---

## 5. Authentication

Authentication is **not currently configured**. The initializer contains commented-out examples for:

| Method | Pattern |
|--------|---------|
| Devise admin check | `user_signed_in? && current_user.admin?` |
| Session-based | `session[:user_id]` lookup |
| Warden | `warden.authenticate!` |
| HTTP Basic Auth | `authenticate_or_request_with_http_basic` |
| Custom | `current_user.can_access_rails_pulse?` |

To enable, uncomment and configure one of the patterns in `config/initializers/rails_pulse.rb`.

---

## 6. Deployment Tracking

Mark deployments on the performance timeline via:

```bash
curl -X POST https://yourapp.com/rails_pulse/deployments \
  -H "X-Rails-Pulse-Token: $RAILS_PULSE_DEPLOYMENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"deployment": {"revision": "abc1234", "metadata": {"environment": "production"}}}'
```

Or via rake task:

```bash
rake rails_pulse:record_deployment[abc1234]
```

Set the API token in the initializer:

```ruby
config.deployment_api_token = ENV["RAILS_PULSE_DEPLOYMENT_TOKEN"]
```

---

## 7. Dashboard Access

Navigate to `/rails_pulse` in the browser. The dashboard shows:

- **Requests** — Response time percentiles, throughput, error rate
- **Routes** — Per-route performance breakdown
- **Queries** — Slow query analysis, N+1 detection
- **Jobs** — Job duration, failure rate (if `track_jobs` enabled)
- **Summaries** — Aggregated hourly/daily/weekly/monthly stats
- **Deployments** — Visual markers on performance charts

---

## 8. Data Cleanup

RailsPulse runs automatic cleanup to manage database size:

1. **Time-based**: Deletes records older than `full_retention_period` (2 weeks)
2. **Count-based**: After time cleanup, if tables exceed `max_table_records`, oldest records are pruned

Cleanup respects foreign key constraints: `operations` → `requests` → `queries`/`routes`.

---

## 9. Schema Tables

| Table | Records | Key Columns |
|-------|---------|-------------|
| `rails_pulse_deployments` | Deployment markers | `revision`, `started_at`, `finished_at` |
| `rails_pulse_jobs` | Job class definitions | `name`, `avg_duration`, `p95_duration` |
| `rails_pulse_job_runs` | Individual executions | `duration`, `status`, `error_class` |
| `rails_pulse_operations` | Fine-grained operations | `operation_type`, `label`, `duration`, `actual_sql` |
| `rails_pulse_queries` | Normalized SQL | `hashed_sql` (unique), `explain_plan`, `index_recommendations` |
| `rails_pulse_requests` | HTTP requests | `duration`, `status`, `controller_action` |
| `rails_pulse_routes` | Route definitions | `method`, `path` (unique) |
| `rails_pulse_summaries` | Aggregated stats | `period_start`, `period_type`, percentile columns |

---

## 10. Adding to a New Environment

1. Add database config in `config/database.yml`:
```yaml
rails_pulse:
  <<: *rails_pulse
  database: skycom_pulse_<environment>
```

2. Ensure the Docker Compose service is running:
```yaml
pulse_postgres:
  image: postgres:16
  ports:
    - "5433:5432"
```

3. Create and migrate the database:
```bash
bin/rails db:create:rails_pulse
bin/rails db:migrate:rails_pulse
```

---

*End of file*
