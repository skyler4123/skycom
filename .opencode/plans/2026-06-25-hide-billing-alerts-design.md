# Hide Billing Alerts + Flexible suspension_at

**Date**: 2026-06-25  
**Status**: Approved

## Problem

When extending a past_due company's `suspension_at` date manually (allowing them to operate while accumulating unpaid invoices), the frontend still shows "past_due" warning banners and toasts to their staff. This is distracting and causes confusion — the extension is intentional, and the payment warning should be suppressed.

## Solution

Add a `hide_billing_alerts` boolean column to `companies`. When true, the `set_past_due_warning` before-action in `ApplicationController` skips the flash alert. No other behavior changes — invoicing, suspension enforcement, and bulk payment all work identically.

## Column

| Column | Type | Default | Description |
|--------|------|---------|-------------|
| `hide_billing_alerts` | boolean | `false` | Suppresses past_due UI warnings when true |

`suspension_at` already exists — no changes needed. Manually pushing it forward extends the company's runway while `MonthlyBillingJob` continues accruing invoices.

## Code Changes

### 1. Migration

```ruby
class AddHideBillingAlertsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :hide_billing_alerts, :boolean, default: false, null: false
  end
end
```

### 2. ApplicationController (`app/controllers/companies/application_controller.rb`)

Add a `hide_billing_alerts?` guard to `set_past_due_warning`:

```ruby
def set_past_due_warning
  return unless current_company&.lifecycle_status_past_due?
  return if current_company.hide_billing_alerts?
  return unless Time.current.day >= 15
  flash.now[:alert] = "Your account is past due..."
end
```

### 3. No other changes needed

- `MonthlyBillingJob` — already invoices past_due companies; no change
- `MonthlySuspensionJob` — already checks `suspension_at <= Time.current`; extending date naturally delays enforcement
- `block_suspended!` — already redirects suspended companies; no change
- `BillingController` — already shows accumulated invoices for bulk pay; no change
- `try_reactivate!` — already clears `suspension_at` on full payment; no change
- `mark_past_due!` — already sets `suspension_at = end_of_month`; no change
- `docs/MODEL_CALLBACKS.md` — no callback changes to document

## Test Coverage

- Model spec: `hide_billing_alerts` defaults to `false`
- Controller spec: warning skips when `hide_billing_alerts` is true on a past_due company
- Controller spec: warning still shows when `hide_billing_alerts` is false on a past_due company (day >= 15)
