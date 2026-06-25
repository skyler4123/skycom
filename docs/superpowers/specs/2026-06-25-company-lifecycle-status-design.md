# Company Lifecycle Status — Production Billing Design

> **Problem**: The Company `lifecycle_status` enum uses generic demo values (`active`, `inactive`, `archived`, `suspended`, `deleted`) shared across 46+ models. The billing pipeline (`SettlementService`) immediately trips the circuit breaker to `:suspended` on shortfall, tightly coupling payment outcome to access enforcement.
>
> **Goal**: Replace with Company-specific billing-status values and decouple status-setting from enforcement.

---

## 1. New Company Lifecycle Status Enum

Company gets its own enum (the shared `LIFECYCLE_STATUS` constant stays for other models):

| Value | Integer | Semantics | Billing State |
|-------|---------|-----------|---------------|
| `active` | 0 | Good standing — full operations | Paid in full |
| `past_due` | 10 | Payment overdue — within grace period | Shortfall (billing couldn't collect) |
| `suspended` | 20 | Access blocked — grace period expired | Unpaid after grace |
| `disabled` | 30 | Permanently closed | Terminal |

**Why spaced integers**: Avoids value conflicts during migration (old `suspended=3` → new `suspended=20`, old `archived=2` → new `disabled=30`). No overlap.

### Enum in Company model

```ruby
# app/models/company.rb
enum :lifecycle_status, {
  active: 0,
  past_due: 10,
  suspended: 20,
  disabled: 30
}, prefix: true, default: :active
```

### Shared LIFECYCLE_STATUS constant

Stays unchanged at `config/initializers/constants.rb` for the 46 other models (Product, Employee, Branch, etc.):

```ruby
LIFECYCLE_STATUS = {
  active: 0,
  inactive: 1,
  archived: 2,
  suspended: 3,
  deleted: 4
}.freeze
```

---

## 2. Data Migration

Map existing Company records to new values:

| Old Value | Old Integer | → | New Value | New Integer |
|-----------|-------------|---|-----------|-------------|
| `active` | 0 | → | `active` | 0 |
| `inactive` | 1 | → | `active` | 0 |
| `archived` | 2 | → | `disabled` | 30 |
| `suspended` | 3 | → | `suspended` | 20 |
| `deleted` | 4 | → | `disabled` | 30 |

SQL (single migration, ordered to avoid conflicts):

```ruby
Company.where(lifecycle_status: 1).update_all(lifecycle_status: 0)   # inactive → active
Company.where(lifecycle_status: 3).update_all(lifecycle_status: 20)  # suspended → suspended(20)
Company.where(lifecycle_status: 2).update_all(lifecycle_status: 30)  # archived → disabled
Company.where(lifecycle_status: 4).update_all(lifecycle_status: 30)  # deleted → disabled
```

---

## 3. CircuitBreakerConcern — Updated State Machine

**File**: `app/models/concerns/company/circuit_breaker_concern.rb`

### Method changes

| Current | New | Transition | Called By |
|---------|-----|-----------|-----------|
| `circuit_breaker_trip!` | `mark_past_due!` | any → `past_due` | `SettlementService` |
| (same) | `suspend!` (renamed from `trip!`) | any → `suspended` | Enforcement process (future), admin |
| `circuit_breaker_reset!` | (same) | `past_due` or `suspended` → `active` | Auto-recovery callback |

### Auto-recovery logic

```ruby
after_update :auto_reset_circuit_breaker,
  if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }

def auto_reset_circuit_breaker
  return unless lifecycle_status_past_due? || lifecycle_status_suspended?
  return if debt_ceiling_reached?
  circuit_breaker_reset!
end
```

### Key invariant

Only `mark_past_due!` and `suspend!` move the status away from `active`. The `reset!` method moves back to `active`. `disabled` is terminal (no transition out).

---

## 4. SettlementService — Decoupled Outcome

**File**: `app/services/billing/settlement_service.rb`

### Change

```ruby
# Before (lines 86-93):
def handle_shortfall(remaining)
  company.circuit_breaker_trip!   # directly suspends
  invoice.update!(payment_status: :overdue)
end

# After:
def handle_shortfall(remaining)
  company.mark_past_due!          # sets status, doesn't enforce
  invoice.update!(payment_status: :overdue)
end
```

SettlementService no longer decides whether to suspend. It records the billing outcome (`past_due`) and lets the independent enforcement process decide what to do next (grace period, notifications, eventual suspension).

---

## 5. MonthlyBillingJob — Broader Scope

**File**: `app/jobs/billing/monthly_billing_job.rb`

```ruby
# Before (line 19):
Company.lifecycle_status_active.find_each(batch_size: 50)

# After:
Company.where(lifecycle_status: Company.lifecycle_statuses.values_at(:active, :past_due))
       .find_each(batch_size: 50)
```

Companies that are `past_due` still get billed. If they've topped up since the last attempt, payment succeeds and auto-recovery resets them to `active`. If still insolvent, they stay `past_due`. Companies that are `suspended` or `disabled` are skipped.

---

## 6. Enforcement (Future — User Handles)

The following is NOT part of this implementation. It's the independent process you'll build later:

```ruby
# Example enforcement job (not implemented here):
class Billing::EnforceOverdueJob
  def perform
    Company.lifecycle_status_past_due.find_each do |company|
      # Check grace period expiry
      # Retry card charge
      # Send notifications
      # If grace expired → company.suspend!
    end
  end
end
```

---

## 7. Changed Files Summary

| File | Change |
|------|--------|
| `app/models/company.rb` | Add new `lifecycle_status` enum (Company-specific) |
| `app/models/concerns/company/circuit_breaker_concern.rb` | Rename `trip!` → `suspend!`; add `mark_past_due!`; update auto-recovery |
| `app/services/billing/settlement_service.rb` | Replace `circuit_breaker_trip!` → `mark_past_due!` |
| `app/jobs/billing/monthly_billing_job.rb` | Scope: active + past_due |
| Migration file | Reassign old enum values (see §2) |
| `spec/models/concerns/company/circuit_breaker_concern_spec.rb` | Update method names and expectations |
| `spec/services/billing/settlement_service_spec.rb` | Expect `past_due`, not `suspended` |
| `spec/jobs/billing/monthly_billing_job_spec.rb` | Update scope expectations |

### Unchanged

- `config/initializers/constants.rb` — LIFECYCLE_STATUS stays for other models
- `app/models/concerns/company/billing_concern.rb` — `debt_ceiling_reached?` logic unchanged
- All other models (Product, Employee, etc.) — their lifecycle_status enums are unaffected
- Client cache / frontend — no changes needed
- Policies — no changes needed

---

## 8. Error & Edge Cases

| Scenario | Behavior |
|----------|----------|
| Settlement runs on already-past_due company | `mark_past_due!` is idempotent — no-op if already `past_due` |
| Auto-recovery when balances don't cover threshold | Stays in current state — no premature reset |
| Admin manually calls `suspend!` | Transitions directly to `suspended` (grace period bypassed) |
| Recovery from `disabled` | Not allowed — `disabled` is terminal (enforced in CircuitBreakerConcern) |
| MonthlyBillingJob on `suspended` company | Skipped — not in the active+past_due scope |

---

## 9. Testing Strategy

| Component | Key Assertions |
|-----------|----------------|
| CircuitBreakerConcern | `mark_past_due!` sets past_due; `suspend!` sets suspended; auto-recovery from both; `disabled` is terminal |
| SettlementService | Shortfall → company `past_due`, not `suspended`; invoice `overdue` |
| MonthlyBillingJob | Processes active AND past_due; skips suspended and disabled |

---

*Spec: Approved via brainstorming on 2026-06-25.*
