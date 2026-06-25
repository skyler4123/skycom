# Remove Suspended Enum — Simplify Lifecycle

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `suspended` lifecycle_status from Company, making `past_due` purely financial (has unpaid invoices) and `suspension_at` the sole gate for access blocking. MonthlyBillingJob creates invoices only (no auto-settlement). Payment is voluntary via BillingController.

**Architecture:** `suspension_at` presence+past blocks access (checked in `block_access!`). Past_due is set when unpaid invoices exist, cleared when all are paid. MonthlyBillingJob creates invoices (InvoiceService) but skips SettlementService. SettlementService is called only from BillingController (pay_all) or `attempt_settle_outstanding` (balance change callback). QR/bank transfer flow is frontend — backend returns `remaining_cents`.

**Tech Stack:** Ruby on Rails 8, PostgreSQL

---

### Task 1: Migration — Convert suspended records + remove enum value

**Files:**
- Create: `db/migrate/TIMESTAMP_remove_suspended_from_company_lifecycle.rb`
- Modify: `app/models/company.rb` (enum definition)

- [ ] **Step 1: Create migration**

```bash
bin/rails generate migration RemoveSuspendedFromCompanyLifecycle
```

- [ ] **Step 2: Write migration — convert existing + remove**

```ruby
# db/migrate/TIMESTAMP_remove_suspended_from_company_lifecycle.rb
class RemoveSuspendedFromCompanyLifecycle < ActiveRecord::Migration[8.0]
  def up
    # Convert existing suspended companies to past_due (keep their suspension_at if set)
    Company.where(lifecycle_status: 20).update_all(lifecycle_status: 10)
    # ^ 20 was suspended, 10 is past_due
  end

  def down
    # Cannot restore — we don't know which were originally suspended
    raise ActiveRecord::IrreversibleMigration
  end
end
```

- [ ] **Step 3: Update enum in Company model**

Remove `suspended: 20` from the lifecycle_status enum:

```ruby
# app/models/company.rb
enum :lifecycle_status, {
  active: 0,
  past_due: 10,
  disabled: 30
}, prefix: true, default: :active
```

- [ ] **Step 4: Run migration**

```bash
bin/rails db:migrate
bin/rails db:migrate RAILS_ENV=test
```

---

### Task 2: CircuitBreakerConcern — remove suspend!, simplify helpers

**Files:**
- Modify: `app/models/concerns/company/circuit_breaker_concern.rb`

- [ ] **Step 1: Rewrite concern**

Replace the entire file:

```ruby
# frozen_string_literal: true

# Manages Company lifecycle based on unpaid invoices.
#
# mark_past_due! is called when unpaid invoices exist:
#   - Sets lifecycle_status → :past_due
#   - Sets suspension_at → end of current month (gives runway)
#
# Admin can extend suspension_at to give more time.
# Access is blocked when suspension_at.present? && suspension_at <= Time.current
# (checked in block_access! in Authorizable concern).
#
# try_reactivate! is called after an invoice is marked paid:
#   - If no unpaid invoices remain → sets lifecycle_status → :active, clears suspension_at
#
# On balance change (main or promo), attempt_settle_outstanding fires:
#   Tries to settle unpaid invoices oldest-first from wallet.
#
# disabled is terminal — no transitions out of it.
#
module Company::CircuitBreakerConcern
  extend ActiveSupport::Concern

  TERMINAL_STATES = %w[disabled].freeze

  included do
    after_update :attempt_settle_outstanding, if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }
  end

  def mark_past_due!
    assert_not_terminal!
    return if lifecycle_status_past_due?

    update!(
      lifecycle_status: :past_due,
      suspension_at: Time.current.end_of_month
    )
  end

  def try_reactivate!
    return if lifecycle_status_disabled?
    return if billing_invoices.where(payment_status: %i[unpaid overdue]).exists?

    update!(lifecycle_status: :active, suspension_at: nil)
  end

  def access_blocked?
    suspension_at.present? && suspension_at <= Time.current
  end

  private

  def assert_not_terminal!
    return unless lifecycle_status.to_s.in?(TERMINAL_STATES)

    errors.add(:base, "Cannot transition from terminal state: #{lifecycle_status}")
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def attempt_settle_outstanding
    return if Thread.current[:__settling_company_id] == id
    return unless lifecycle_status_past_due?
    return unless main_balance_cents.positive? || promo_balance_cents.positive?
    return unless billing_invoices.where(payment_status: %i[unpaid overdue]).exists?

    Thread.current[:__settling_company_id] = id
    begin
      Billing::SettlementService.settle_all(self)
    ensure
      Thread.current[:__settling_company_id] = nil
    end
  end
end
```

Key changes:
- Removed `suspend!` method entirely
- Removed `circuit_breaker_reset!` (no longer needed — `try_reactivate!` covers it)
- `mark_past_due!` — removed `lifecycle_status_suspended?` guard
- `try_reactivate!` — unchanged
- Added `access_blocked?` — checks `suspension_at.present? && suspension_at <= Time.current`
- `attempt_settle_outstanding` — removed `suspended` check, only fires for past_due

---

### Task 3: Authorizable concern — rename block_suspended! to block_access!

**Files:**
- Modify: `app/controllers/concerns/companies/authorizable.rb`

- [ ] **Step 1: Rewrite block_suspended! as block_access!**

```ruby
def block_access!
  return unless current_company&.access_blocked?

  respond_to do |format|
    format.html do
      redirect_to company_billing_path(current_company), alert: "Your account is suspended. Please resolve outstanding invoices."
    end
    format.json do
      render json: { errors: [ "Account is suspended" ] }, status: :forbidden
    end
  end
end
```

---

### Task 4: ApplicationController — update before_action name

**Files:**
- Modify: `app/controllers/companies/application_controller.rb`

- [ ] **Step 1: Change before_action and set_past_due_warning**

```ruby
class Companies::ApplicationController < ApplicationController
  before_action :set_company
  before_action :set_employee
  before_action :block_access!
  before_action :set_past_due_warning

  include Companies::Authorizable

  private
  # ... set_company, set_employee, current_company, current_employee unchanged ...

  def set_past_due_warning
    return unless current_company&.lifecycle_status_past_due?
    return if current_company.hide_billing_alerts?
    return unless Time.current.day >= 15

    flash.now[:alert] = "Your account is past due. Please settle outstanding invoices to avoid suspension."
  end
end
```

---

### Task 5: BillingController — update skip_before_action

**Files:**
- Modify: `app/controllers/companies/billing_controller.rb`

- [ ] **Step 1: Update skip and pay_all response**

```ruby
class Companies::BillingController < Companies::ApplicationController
  skip_before_action :block_access!, only: %i[show pay_all]

  def show
    # ... unchanged ...
  end

  def pay_all
    invoices = current_company.billing_invoices
                              .where(payment_status: %i[unpaid overdue])
                              .order(:created_at)

    if invoices.none?
      return render json: { message: "No outstanding invoices.", reactivated: false, remaining_cents: 0 }
    end

    total_unpaid_cents = invoices.sum(:price_cents)
    paid_count = Billing::SettlementService.settle_all(current_company)

    company = current_company.reload
    remaining_cents = company.billing_invoices
                             .where(payment_status: %i[unpaid overdue])
                             .sum(:price_cents)

    reactivated = company.lifecycle_status_active?

    render json: {
      message: reactivated ? "All invoices paid. Account reactivated!" : "Invoices settled.",
      paid_count: paid_count,
      reactivated: reactivated,
      remaining_cents: remaining_cents
    }
  end
end
```

---

### Task 6: MonthlyBillingJob — remove auto-settlement

**Files:**
- Modify: `app/jobs/billing/monthly_billing_job.rb`

- [ ] **Step 1: Remove SettlementService call, add past_due check**

```ruby
module Billing
  class MonthlyBillingJob < ApplicationJob
    queue_as :default

    def perform
      Company.where.not(lifecycle_status: :disabled).find_each(batch_size: 50) do |company|
        process_company(company)
      rescue StandardError => e
        Rails.logger.error("MonthlyBillingJob: Failed for company #{company.id}: #{e.message}")
      end
    end

    private

    def process_company(company)
      result = CalculatorService.call(company)
      return if result.total_cents.zero? && result.breakdown&.total_cents.to_i.zero?

      invoice = InvoiceService.call(company, result)
      return unless invoice

      # If company now has unpaid invoices, mark as past_due
      company.mark_past_due! if company.billing_invoices.where(payment_status: %i[unpaid overdue]).exists?
    end
  end
end
```

---

### Task 7: Remove MonthlySuspensionJob

- [ ] **Step 1: Delete job file**

```bash
rm app/jobs/billing/monthly_suspension_job.rb
```

- [ ] **Step 2: Remove from recurring.yml**

```yaml
# Remove these lines:
#   monthly_suspension:
#     class: Billing::MonthlySuspensionJob
#     queue: default
#     schedule: at 00:05 day 1 every month
```

---

### Task 8: SettlementService — return remaining_cents from settle_all

**Files:**
- Modify: `app/services/billing/settlement_service.rb`

- [ ] **Step 1: Add remaining_cents to settle_all return value**

```ruby
def self.settle_all(company)
  settling = (Thread.current[:__settling_companies] ||= Set.new)
  return { paid_count: 0, remaining_cents: 0 } unless settling.add?(company.id)

  unpaid = company.billing_invoices
                  .where(payment_status: %i[unpaid overdue])
                  .order(:created_at)

  paid_count = 0
  unpaid.each do |invoice|
    call(invoice)
    paid_count += 1 if invoice.reload.paid?
  end

  remaining_cents = company.billing_invoices
                           .where(payment_status: %i[unpaid overdue])
                           .sum(:price_cents)

  { paid_count: paid_count, remaining_cents: remaining_cents }
ensure
  Thread.current[:__settling_companies]&.delete(company&.id)
end
```

And update `handle_shortfall` to not call `mark_past_due!` since the company should already be past_due:

Actually, `handle_shortfall` should still call `mark_past_due!` — it's idempotent and covers edge cases where an active company somehow has an unpaid invoice being settled.

No change needed to `handle_shortfall`.

---

### Task 9: Update tests

**Files:**
- Modify: `spec/models/concerns/company/circuit_breaker_concern_spec.rb`
- Modify: `spec/jobs/billing/monthly_billing_job_spec.rb`
- Modify: `spec/services/billing/settlement_service_spec.rb`
- Modify: `spec/requests/companies/application_controller_spec.rb`
- Modify: `spec/models/company_spec.rb`
- Create: `spec/requests/companies/billing_controller_spec.rb`
- Delete: `spec/jobs/billing/monthly_suspension_job_spec.rb`

#### Step 1: Update company model spec

Change the lifecycle_status enum test to remove suspended:

```ruby
# spec/models/company_spec.rb
describe "lifecycle_status" do
  it "defines company-specific billing values" do
    expect(Company.lifecycle_statuses).to eq({
      "active" => 0,
      "past_due" => 10,
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

#### Step 2: Update circuit_breaker_concern_spec

```ruby
# spec/models/concerns/company/circuit_breaker_concern_spec.rb
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

    it "sets suspension_at to end of current month" do
      company.mark_past_due!
      expect(company.reload.suspension_at).to be_within(1.day).of(Time.current.end_of_month)
    end

    it "is idempotent when already past_due" do
      company.update!(lifecycle_status: :past_due)
      expect { company.mark_past_due! }.not_to raise_error
    end
  end

  describe "#access_blocked?" do
    it "returns true when suspension_at is in the past" do
      company.update!(suspension_at: 1.day.ago)
      expect(company.access_blocked?).to be true
    end

    it "returns false when suspension_at is nil" do
      expect(company.access_blocked?).to be false
    end

    it "returns false when suspension_at is in the future" do
      company.update!(suspension_at: 1.day.from_now)
      expect(company.access_blocked?).to be false
    end
  end

  describe "#try_reactivate!" do
    it "transitions from past_due to active when no unpaid invoices exist" do
      company.update!(lifecycle_status: :past_due, suspension_at: Time.current.end_of_month)
      company.try_reactivate!
      expect(company.reload.lifecycle_status).to eq("active")
    end

    it "clears suspension_at on reactivation" do
      company.update!(lifecycle_status: :past_due, suspension_at: Time.current.end_of_month)
      company.try_reactivate!
      expect(company.reload.suspension_at).to be_nil
    end

    it "stays past_due when unpaid invoices exist" do
      company.update!(lifecycle_status: :past_due)
      create(:billing_invoice, company: company, payment_status: :unpaid, price_cents: 1000)
      company.try_reactivate!
      expect(company.reload.lifecycle_status).to eq("past_due")
    end

    it "transitions when all invoices are paid" do
      company.update!(lifecycle_status: :past_due)
      create(:billing_invoice, company: company, payment_status: :paid, price_cents: 1000)
      company.try_reactivate!
      expect(company.reload.lifecycle_status).to eq("active")
    end
  end

  describe "attempt_settle_outstanding on balance change" do
    it "does not fire for active companies" do
      expect(Billing::SettlementService).not_to receive(:settle_all)
      company.update!(main_balance_cents: 5000)
    end

    it "fires for past_due companies with unpaid invoices" do
      company.update!(lifecycle_status: :past_due)
      create(:billing_invoice, company: company, payment_status: :unpaid, price_cents: 1000)
      expect(Billing::SettlementService).to receive(:settle_all).with(company).and_call_original
      company.update!(main_balance_cents: 5000)
    end
  end

  describe "#disabled is terminal" do
    before do
      company.update!(lifecycle_status: :disabled, main_balance_cents: 0,
                      promo_balance_cents: 0)
    end

    it "does not allow mark_past_due! on disabled company" do
      expect { company.mark_past_due! }
        .to raise_error(ActiveRecord::RecordInvalid, /disabled/)
    end
  end
end
```

#### Step 3: Update monthly_billing_job_spec

Remove the "suspended" context, update the assertion on settlement:

```ruby
# In the "when company is past_due" context:
context "when company is past_due" do
  before do
    company.update!(lifecycle_status: :past_due, promo_balance_cents: 2000, main_balance_cents: 0)
  end

  it "still creates a BillingInvoice" do
    expect { perform_job }.to change(BillingInvoice, :count).by(1)
  end

  it "does not auto-settle (invoice stays unpaid)" do
    perform_job
    expect(BillingInvoice.last.payment_status).to eq("unpaid")
  end
end

# In the "when company is disabled" context — unchanged
```

#### Step 4: Update settlement_service_spec

Update `settle_all` tests to check the new return format:

```ruby
describe ".settle_all" do
  # ... let!(:invoice1), let!(:invoice2) same as before ...

  before do
    company.update_columns(
      lifecycle_status: Company.lifecycle_statuses[:past_due],
      main_balance_cents: 3500,
      promo_balance_cents: 0,
      soft_debt_threshold_cents: -10000
    )
    company.reload
  end

  it "returns paid_count and remaining_cents" do
    result = described_class.settle_all(company)
    expect(result).to eq({ paid_count: 2, remaining_cents: 0 })
  end

  it "stops when wallet is exhausted" do
    company.update_columns(main_balance_cents: 1500)
    company.reload
    result = described_class.settle_all(company)
    expect(result[:paid_count]).to eq(1)
    expect(result[:remaining_cents]).to eq(1000)  # invoice2 still unpaid
  end
end
```

#### Step 5: Update application_controller_spec

```ruby
# spec/requests/companies/application_controller_spec.rb
describe "block_access!" do
  it "redirects to billing page when suspension_at is in the past" do
    company.update_columns(suspension_at: 1.day.ago)
    company.reload
    get "/companies/#{company.id}/dashboards"
    expect(response).to redirect_to(company_billing_path(company))
  end

  it "allows access when suspension_at is nil" do
    company.update_columns(suspension_at: nil)
    company.reload
    get "/companies/#{company.id}/dashboards"
    expect(response).to have_http_status(:ok)
  end

  it "allows access when suspension_at is in the future" do
    company.update_columns(suspension_at: 1.week.from_now)
    company.reload
    get "/companies/#{company.id}/dashboards"
    expect(response).to have_http_status(:ok)
  end
end
```

#### Step 6: Delete monthly_suspension_job_spec

```bash
rm spec/jobs/billing/monthly_suspension_job_spec.rb
```

---

### Task 10: Lint, full test suite, commit

- [ ] **Step 1: Run rubocop**

```bash
bin/rubocop --autocorrect-all
```

### Task 10: Update docs/MODEL_CALLBACKS.md

- [ ] **Step 1: Remove MonthlySuspensionJob entry, update CircuitBreakerConcern entry**

Remove the MonthlySuspensionJob callback entry. Update CircuitBreakerConcern to remove `suspend!` and `circuit_breaker_reset!`. Add `access_blocked?`.

- [ ] **Step 2: Run full billing test suite**

```bash
bundle exec rspec spec/models/concerns/company/circuit_breaker_concern_spec.rb
bundle exec rspec spec/jobs/billing/monthly_billing_job_spec.rb
bundle exec rspec spec/services/billing/settlement_service_spec.rb
bundle exec rspec spec/requests/companies/application_controller_spec.rb
bundle exec rspec spec/models/company_spec.rb
```

Expected: All green.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: remove suspended lifecycle_status, use suspension_at for access control"
```
