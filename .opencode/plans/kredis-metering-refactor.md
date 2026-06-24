# Kredis Metering Refactor

## Goal
Replace raw Redis `INCRBY` usage for billing counters with Kredis-backed counters featuring `default` lambda fallback for Redis restart safety. Sync to PostgreSQL every 4 hours.

## Changes

### 1. `app/models/concerns/company/billing_concern.rb`

Add two new public methods before `record_usage!`:

```ruby
def daily_meter(resource_key, log_date: Date.current)
  key = "skycom:company:#{id}:#{resource_key}:#{log_date.strftime('%Y%m%d')}"
  Kredis.integer(key, default: -> {
    DailyUsageLog.where(company_id: id)
                 .joins(:billing_resource)
                 .where(billing_resources: { name: resource_key.to_s })
                 .where(log_date: log_date)
                 .sum(:usage_count)
  })
end

def meter_usage(resource_key, log_date: Date.current)
  daily_meter(resource_key, log_date: log_date).value.to_i
end
```

`record_usage!` stays as-is (atomic `incrby` for writes).

### 2. `app/jobs/billing/sync_daily_usage_job.rb`

In `process_key`, replace raw `Kredis.redis.get(key).to_i` with `company.meter_usage(resource_name, log_date)` so the Kredis default lambda re-hydrates on nil.

```ruby
def process_key(key, log_date)
  parts = key.split(":")
  company_id = parts[2]
  resource_name = parts[3]

  company = Company.find_by(id: company_id)
  resource = BillingResource.find_by(name: resource_name)

  unless company && resource
    Rails.logger.warn("SyncDailyUsageJob: Skipping key #{key} — company or resource not found")
    return
  end

  value = company.meter_usage(resource_name, log_date: log_date)
  return if value.zero?

  DailyUsageLog.find_or_initialize_by(
    company: company,
    billing_resource: resource,
    log_date: log_date
  ).update!(usage_count: value)

  Kredis.redis.del(key)
rescue ActiveRecord::RecordInvalid, Redis::BaseConnectionError => e
  Rails.logger.warn("SyncDailyUsageJob: Error processing key #{key}: #{e.message}")
end
```

### 3. `config/recurring.yml`

Change sync_daily_usage from `at 23:55 every day` to `every 4 hours`.

### 4. `spec/models/concerns/company/billing_concern_spec.rb`

Add tests for `daily_meter` and `meter_usage`:
- Returns Kredis integer proxy
- Returns 0 when no usage exists
- Returns accumulated value after `record_usage!`
- Falls back to DailyUsageLog sum when Redis key is missing

### 5. `spec/jobs/billing/sync_daily_usage_job_spec.rb`

Update tests — same coverage (create DailyUsageLog, correct count, delete Redis key) but now exercises `meter_usage` codepath.

### 6. Verify

```bash
bin/rails t spec/models/concerns/company/billing_concern_spec.rb spec/models/concerns/metering_concern_spec.rb spec/jobs/billing/ spec/services/billing/
bin/rubocop --autocorrect-all
```
