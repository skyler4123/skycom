# Company Lifecycle Status Production Refactor

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Company's generic lifecycle_status enum with production billing-status values (`active`, `past_due`, `suspended`, `disabled`) and decouple billing outcome from access enforcement.

**Architecture:** Company gets its own enum (shared `LIFECYCLE_STATUS` constant stays for 46 other models). SettlementService sets `past_due` instead of calling `circuit_breaker_trip!`. CircuitBreakerConcern gets `mark_past_due!` and renamed `suspend!`. Auto-recovery handles both `past_due` and `suspended`. MonthlyBillingJob processes both `active` and `past_due` companies.

**Tech Stack:** Ruby on Rails, ActiveRecord enums, PostgreSQL

**Design doc:** `docs/superpowers/specs/2026-06-25-company-lifecycle-status-design.md` (to be written)

---

### Task 1: Write the design doc

**Files:**
- Create: `docs/superpowers/specs/2026-06-25-company-lifecycle-status-design.md`

- [ ] **Step 1: Write the design doc**

Write the design doc content (see brainstorming output for full text — `docs/superpowers/specs/2026-06-25-company-lifecycle-status-design.md`)

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-06-25-company-lifecycle-status-design.md
git commit -m "docs: add lifecycle_status refactor design spec"
```

---

### Task 2: Define Company-specific lifecycle_status enum

**Files:**
- Modify: `app/models/company.rb` — add Company-specific enum
- Create: migration file for data migration

- [ ] **Step 1: Write the failing test for the new enum**

Add to `spec/models/company_spec.rb`:

```ruby
describe "lifecycle_status enum" do
  it "defines company-specific values" do
    expect(Company.lifecycle_statuses).to eq({
      "active" => 0,
      "past_due" => 10,
      "suspended" => 20,
      "disabled" => 30
    })
  end

  it "defaults to active" do
    expect(Company.new.lifecycle_status).to eq("active")
  end

  it "provides predicate methods" do
    company = Company.new(lifecycle_status: :past_due)
    expect(company).to be_lifecycle_status_past_due
    expect(company).not_to be_lifecycle_status_active
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/models/company_spec.rb -e "lifecycle_status enum" --format documentation`
Expected: NameError about undefined enum values (since old enum uses shared constant)

- [ ] **Step 3: Add Company-specific enum in company.rb**

In `app/models/company.rb`, replace the existing enum line with:

```ruby
# Remove or comment out:
#   enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true

# Add:
enum :lifecycle_status, {
  active: 0,
  past_due: 10,
  suspended: 20,
  disabled: 30
}, prefix: true
```

Keep the existing `LIFECYCLE_STATUS` constant for other models at `config/initializers/constants.rb`.

- [ ] **Step 4: Create migration for existing data**

Run: `bin/rails generate migration RemapCompanyLifecycleStatus`

In the migration:

```ruby
class RemapCompanyLifecycleStatus < ActiveRecord::Migration[8.0]
  def up
    Company.where(lifecycle_status: 1).update_all(lifecycle_status: 0)   # inactive → active
    Company.where(lifecycle_status: 3).update_all(lifecycle_status: 20)  # suspended → suspended(20)
    Company.where(lifecycle_status: 2).update_all(lifecycle_status: 30)  # archived → disabled
    Company.where(lifecycle_status: 4).update_all(lifecycle_status: 30)  # deleted → disabled
  end

  def down
    # Cannot reliably reverse — old values are lost.
    # Raise to prevent accidental rollback.
    raise ActiveRecord::IrreversibleMigration
  end
end
```

- [ ] **Step 5: Run migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bundle exec rspec spec/models/company_spec.rb -e "lifecycle_status enum" --format documentation`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add app/models/company.rb db/migrate/*_remap_company_lifecycle_status.rb
git commit -m "feat: add Company-specific lifecycle_status enum with active/past_due/suspended/disabled"
```

---

### Task 3: Update CircuitBreakerConcern — add mark_past_due!, rename trip! → suspend!

**Files:**
- Modify: `app/models/concerns/company/circuit_breaker_concern.rb`
- Modify: `spec/models/concerns/company/circuit_breaker_concern_spec.rb`

- [ ] **Step 1: Write the failing tests**

Replace the content of `spec/models/concerns/company/circuit_breaker_concern_spec.rb`:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company::CircuitBreakerConcern do
  subject(:company) { create(:company, lifecycle_status: :active) }

  before do
    company.update!(soft_debt_threshold_cents: -1000,
                    main_balance_cents: 0, promo_balance_cents: 0)
  end

  describe "#mark_past_due!" do
    it "sets lifecycle_status to past_due" do
      expect { company.mark_past_due! }
        .to change { company.reload.lifecycle_status }.from("active").to("past_due")
    end

    it "is idempotent when already past_due" do
      company.update!(lifecycle_status: :past_due)
      expect { company.mark_past_due! }.not_to raise_error
    end
  end

  describe "#suspend!" do
    it "sets lifecycle_status to suspended" do
      expect { company.suspend! }
        .to change { company.reload.lifecycle_status }.from("active").to("suspended")
    end

    it "is idempotent when already suspended" do
      company.update!(lifecycle_status: :suspended)
      expect { company.suspend! }.not_to raise_error
    end
  end

  describe "#circuit_breaker_reset!" do
    it "sets lifecycle_status from past_due to active" do
      company.update!(lifecycle_status: :past_due)
      expect { company.circuit_breaker_reset! }
        .to change { company.reload.lifecycle_status }.from("past_due").to("active")
    end

    it "sets lifecycle_status from suspended to active" do
      company.update!(lifecycle_status: :suspended)
      expect { company.circuit_breaker_reset! }
        .to change { company.reload.lifecycle_status }.from("suspended").to("active")
    end
  end

  describe "auto-recovery on balance change" do
    before { company.update!(lifecycle_status: :past_due) }

    it "recovers from past_due when balance rises above threshold" do
      company.update!(main_balance_cents: 5000)
      expect(company.reload.lifecycle_status).to eq("active")
    end

    it "recovers from suspended when balance rises above threshold" do
      company.update!(lifecycle_status: :suspended, main_balance_cents: 5000)
      expect(company.reload.lifecycle_status).to eq("active")
    end

    it "stays past_due if balance is still below threshold" do
      company.update!(main_balance_cents: -2000)
      expect(company.reload.lifecycle_status).to eq("past_due")
    end
  end

  describe "#disabled is terminal" do
    it "does not allow mark_past_due! on disabled company" do
      company.update!(lifecycle_status: :disabled)
      expect { company.mark_past_due! }
        .to raise_error(ActiveRecord::RecordInvalid, /disabled/)
    end

    it "does not allow reset from disabled" do
      company.update!(lifecycle_status: :disabled, main_balance_cents: 5000)
      expect(company.reload.lifecycle_status).to eq("disabled")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/models/concerns/company/circuit_breaker_concern_spec.rb --format documentation`
Expected: Multiple failures (methods not found / enum values wrong)

- [ ] **Step 3: Rewrite circuit_breaker_concern.rb**

Replace the content of `app/models/concerns/company/circuit_breaker_concern.rb`:

```ruby
# frozen_string_literal: true

# Controls Company lifecycle_status transitions for billing enforcement.
#
# SettlementService calls mark_past_due! when payment cannot be collected:
#   company.mark_past_due!  # lifecycle_status → :past_due
#
# Enforcement process (separate) calls suspend! after grace period expires:
#   company.suspend!  # lifecycle_status → :suspended
#
# Auto-recovery fires on any balance change — if past_due or suspended
# and wallet is above soft_debt_threshold, resets to :active.
#
module Company::CircuitBreakerConcern
  extend ActiveSupport::Concern

  TERMINAL_STATES = %w[disabled].freeze

  included do
    after_update :auto_reset_circuit_breaker,
      if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }
  end

  def mark_past_due!
    return if lifecycle_status_past_due?
    assert_not_terminal!
    update!(lifecycle_status: :past_due)
  end

  def suspend!
    return if lifecycle_status_suspended?
    assert_not_terminal!
    update!(lifecycle_status: :suspended)
  end

  def circuit_breaker_reset!
    return unless lifecycle_status_past_due? || lifecycle_status_suspended?

    update!(lifecycle_status: :active)
  end

  private

  def auto_reset_circuit_breaker
    return unless lifecycle_status_past_due? || lifecycle_status_suspended?
    return if debt_ceiling_reached?

    circuit_breaker_reset!
  end

  def assert_not_terminal!
    if lifecycle_status.to_s.in?(TERMINAL_STATES)
      raise ActiveRecord::RecordInvalid.new(self),
        "Cannot transition from terminal state: #{lifecycle_status}"
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/models/concerns/company/circuit_breaker_concern_spec.rb --format documentation`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/models/concerns/company/circuit_breaker_concern.rb spec/models/concerns/company/circuit_breaker_concern_spec.rb
git commit -m "feat: update CircuitBreakerConcern — add mark_past_due!, rename trip!→suspend!, auto-recover from both"
```

---

### Task 4: Update SettlementService — use mark_past_due! instead of circuit_breaker_trip!

**Files:**
- Modify: `app/services/billing/settlement_service.rb`
- Modify: `spec/services/billing/settlement_service_spec.rb`

- [ ] **Step 1: Write the failing test**

In `spec/services/billing/settlement_service_spec.rb`, find the test that asserts circuit breaker trips and update it:

```ruby
# Replace:
it "trips the circuit breaker" do
  expect { settle }
    .to change { company.reload.lifecycle_status }.from("active").to("suspended")
end

# With:
it "marks company as past_due" do
  expect { settle }
    .to change { company.reload.lifecycle_status }.from("active").to("past_due")
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/services/billing/settlement_service_spec.rb --format documentation`
Expected: The existing test fails — expects "suspended" but still gets the old behavior

- [ ] **Step 3: Update SettlementService**

In `app/services/billing/settlement_service.rb`, change:

```ruby
# Before (line 87):
company.circuit_breaker_trip!

# After:
company.mark_past_due!
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/services/billing/settlement_service_spec.rb --format documentation`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/services/billing/settlement_service.rb spec/services/billing/settlement_service_spec.rb
git commit -m "feat: SettlementService uses mark_past_due! instead of circuit_breaker_trip!"
```

---

### Task 5: Update MonthlyBillingJob scope to include past_due

**Files:**
- Modify: `app/jobs/billing/monthly_billing_job.rb`
- Modify: `spec/jobs/billing/monthly_billing_job_spec.rb`

- [ ] **Step 1: Write the failing test**

In `spec/jobs/billing/monthly_billing_job_spec.rb`, add a test verifying past_due companies are processed:

```ruby
context "when a company is past_due" do
  let(:past_due_company) { create(:company, lifecycle_status: :past_due) }

  before do
    create(:billing_contract, company: past_due_company,
           lifecycle_status: :active, start_date: 2.months.ago)
    create(:daily_usage_log, company: past_due_company,
           billing_resource: create(:billing_resource, :volumetric, name: "orders"),
           log_date: Date.current, usage_count: 0)
  end

  it "still processes the company" do
    expect { perform_job }.to change(BillingInvoice, :count).by(1)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/jobs/billing/monthly_billing_job_spec.rb --format documentation`
Expected: Test fails — past_due companies are currently excluded by the scope

- [ ] **Step 3: Update MonthlyBillingJob**

In `app/jobs/billing/monthly_billing_job.rb`, change:

```ruby
# Before (line 19):
Company.lifecycle_status_active.find_each(batch_size: 50)

# After:
Company.where(lifecycle_status: Company.lifecycle_statuses.values_at(:active, :past_due))
       .find_each(batch_size: 50)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/jobs/billing/monthly_billing_job_spec.rb --format documentation`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/jobs/billing/monthly_billing_job.rb spec/jobs/billing/monthly_billing_job_spec.rb
git commit -m "feat: MonthlyBillingJob processes past_due companies too"
```

---

### Task 6: Full spec audit and docs update

**Files:**
- Multiple spec files — verify all pass
- `docs/superpowers/specs/2026-06-25-company-lifecycle-status-design.md` — write design doc
- `docs/MODEL_CALLBACKS.md` — update if needed

- [ ] **Step 1: Write the design doc**

Write `docs/superpowers/specs/2026-06-25-company-lifecycle-status-design.md` with the approved design content.

- [ ] **Step 2: Search for any remaining references to old behavior**

Run: `bin/rails runner 'puts Company.where(lifecycle_status: [1,2,4]).count'`
Expected: 0 — all old values migrated

Run: `grep -r "circuit_breaker_trip!" app/ --include="*.rb"`
Expected: No matches (should be only `suspend!` and `mark_past_due!`)

- [ ] **Step 3: Run the full test suite for all changed components**

Run: `bundle exec rspec spec/models/concerns/company/ spec/services/billing/ spec/jobs/billing/ --format documentation`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-06-25-company-lifecycle-status-design.md
git commit -m "docs: add lifecycle_status refactor design spec"
```

---

### Task 7: Final verification

- [ ] **Step 1: Run rubocop**

Run: `bundle exec rubocop app/models/company.rb app/models/concerns/company/ app/services/billing/ app/jobs/billing/`
Expected: No offenses

- [ ] **Step 2: Run any remaining billing-related specs**

Run: `bundle exec rspec spec/models/concerns/company/ spec/services/billing/ spec/jobs/billing/ --format documentation`
Expected: All greens
