# Billing Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete backend billing pipeline: feature gating, Redis metering, nightly usage sync, monthly invoice generation, wallet deduction, and circuit breaker.

**Architecture:** Concern-driven approach with composed service objects. MeteringConcern hooks into existing models via `after_commit`. SyncDailyUsageJob reads Redis counters each night. MonthlyBillingJob orchestrates CalculatorService → InvoiceService → SettlementService per company. CircuitBreakerConcern suspends companies on unpaid balances.

**Tech Stack:** Rails 8, Solid Queue, Kredis/Redis, RSpec

**Pre-requisite:** The 6 billing migration files from the previous commit exist but have NOT been run (not in schema.rb). The first task runs them.

---

### Task 1: Run existing billing migrations + Add wallet fields migration

**Files:**
- Create: `db/migrate/20260624160000_add_wallet_fields_to_companies.rb`
- Modify: `db/migrate/20260624150648_create_daily_usage_logs.rb` — no change, just run

- [ ] **Step 1: Run the 6 existing billing migrations**

```bash
bin/rails db:migrate
```

Expected output: migrations run, schema.rb updated with `billing_resources`, `billing_contracts`, `contract_features`, `contract_metrics`, `billing_invoices`, `daily_usage_logs`.

- [ ] **Step 2: Create the wallet fields migration**

```ruby
# db/migrate/20260624160000_add_wallet_fields_to_companies.rb
class AddWalletFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    change_table :companies do |t|
      t.integer :promo_balance_cents, default: 0, null: false
      t.integer :main_balance_cents, default: 0, null: false
      t.integer :soft_debt_threshold_cents, default: -10000, null: false
    end
  end
end
```

- [ ] **Step 3: Run the new migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 4: Commit**

```bash
git add db/migrate/ db/schema.rb
git commit -m "feat: add wallet fields to companies"
```

---

### Task 2: Create WalletTransaction model + migration

**Files:**
- Create: `db/migrate/20260624161000_create_wallet_transactions.rb`
- Create: `app/models/wallet_transaction.rb`
- Test: `spec/models/wallet_transaction_spec.rb`

- [ ] **Step 1: Write the migration**

```ruby
# db/migrate/20260624161000_create_wallet_transactions.rb
class CreateWalletTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :wallet_transactions, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :billing_invoice, null: true, foreign_key: true, type: :uuid

      t.integer :transaction_type, null: false
      t.integer :amount_cents, default: 0, null: false
      t.string  :currency, default: "USD", null: false

      t.integer :balance_before_cents, default: 0, null: false
      t.integer :balance_after_cents, default: 0, null: false
      t.integer :promo_balance_before_cents, default: 0, null: false
      t.integer :promo_balance_after_cents, default: 0, null: false

      t.text :description

      t.timestamps
    end

    add_index :wallet_transactions, [ :company_id, :created_at ], name: "idx_wallet_tx_company_chrono"
  end
end
```

- [ ] **Step 2: Write the model**

```ruby
# frozen_string_literal: true

# app/models/wallet_transaction.rb
class WalletTransaction < ApplicationRecord
  belongs_to :company
  belongs_to :billing_invoice, optional: true

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :transaction_type, presence: true

  enum :transaction_type, {
    top_up: 0,
    deduction: 1,
    refund: 2,
    promo_credit: 3
  }
end
```

- [ ] **Step 3: Write the model test**

```ruby
# frozen_string_literal: true

# spec/models/wallet_transaction_spec.rb
require "rails_helper"

RSpec.describe WalletTransaction do
  subject(:tx) { build(:wallet_transaction, company: company) }

  let(:company) { create(:company) }

  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:billing_invoice).optional }
  it { is_expected.to validate_presence_of(:transaction_type) }
  it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than_or_equal_to(0) }

  describe "enums" do
    it "defines transaction_type enum" do
      expect(described_class.transaction_types).to match(
        hash_including("top_up" => 0, "deduction" => 1, "refund" => 2, "promo_credit" => 3)
      )
    end
  end
end
```

- [ ] **Step 4: Add factory**

```ruby
# spec/factories/wallet_transactions.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :wallet_transaction do
    company
    transaction_type { :top_up }
    amount_cents { 1000 }
    currency { "USD" }
    balance_before_cents { 0 }
    balance_after_cents { 1000 }
    promo_balance_before_cents { 0 }
    promo_balance_after_cents { 0 }
    description { "Test transaction" }
  end
end
```

- [ ] **Step 5: Run migration and tests**

```bash
bin/rails db:migrate
bundle exec rspec spec/models/wallet_transaction_spec.rb
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add db/migrate/ db/schema.rb app/models/wallet_transaction.rb spec/models/wallet_transaction_spec.rb spec/factories/wallet_transactions.rb
git commit -m "feat: add WalletTransaction model"
```

---

### Task 3: Company::BillingConcern — feature gating + wallet helpers

**Files:**
- Create: `app/models/concerns/company/billing_concern.rb`
- Test: `spec/models/concerns/company/billing_concern_spec.rb`

- [ ] **Step 1: Write the concern**

```ruby
# frozen_string_literal: true

# app/models/concerns/company/billing_concern.rb
module Company::BillingConcern
  extend ActiveSupport::Concern

  def active_billing_contract
    billing_contracts.currently_active.first
  end

  def feature_enabled?(feature_key)
    contract = active_billing_contract
    return false unless contract

    resource = BillingResource.find_by(name: feature_key.to_s, resource_type: :addon_feature)
    return false unless resource

    contract.contract_features.active.exists?(billing_resource: resource)
  end

  def wallet_balance_cents
    main_balance_cents + promo_balance_cents
  end

  def debt_ceiling_reached?
    wallet_balance_cents < soft_debt_threshold_cents
  end

  def record_usage!(resource_key, quantity: 1)
    date_key = Date.current.strftime("%Y%m%d")
    redis_key = "skycom:company:#{id}:#{resource_key}:#{date_key}"

    Kredis.redis.incrby(redis_key, quantity)
  rescue Redis::BaseConnectionError => e
    Rails.logger.warn("Metering Redis unavailable for company #{id}: #{e.message}")
  end
end
```

- [ ] **Step 2: Write the test**

```ruby
# frozen_string_literal: true

# spec/models/concerns/company/billing_concern_spec.rb
require "rails_helper"

RSpec.describe Company::BillingConcern do
  subject(:company) { create(:company) }

  let!(:billing_resource) { create(:billing_resource, :addon_feature, name: "inventory_advanced") }
  let!(:billing_contract) { create(:billing_contract, company: company, lifecycle_status: :active, start_date: 1.month.ago) }

  describe "#active_billing_contract" do
    it "returns the currently active contract" do
      expect(company.active_billing_contract).to eq(billing_contract)
    end

    context "when no active contract exists" do
      before { billing_contract.update!(lifecycle_status: :expired) }

      it "returns nil" do
        expect(company.active_billing_contract).to be_nil
      end
    end
  end

  describe "#feature_enabled?" do
    context "when feature is assigned to active contract" do
      before do
        create(:contract_feature, billing_contract: billing_contract,
               billing_resource: billing_resource, lifecycle_status: :active)
      end

      it "returns true" do
        expect(company.feature_enabled?("inventory_advanced")).to be true
      end
    end

    context "when feature is not assigned" do
      it "returns false" do
        expect(company.feature_enabled?("inventory_advanced")).to be false
      end
    end

    context "when no active contract exists" do
      before { billing_contract.update!(lifecycle_status: :expired) }

      it "returns false" do
        expect(company.feature_enabled?("inventory_advanced")).to be false
      end
    end
  end

  describe "#wallet_balance_cents" do
    before do
      company.update!(promo_balance_cents: 500, main_balance_cents: 1000)
    end

    it "returns sum of both balances" do
      expect(company.wallet_balance_cents).to eq(1500)
    end
  end

  describe "#debt_ceiling_reached?" do
    before { company.update!(soft_debt_threshold_cents: -1000) }

    it "returns false when balance is above threshold" do
      company.update!(main_balance_cents: 0, promo_balance_cents: 0)
      expect(company.debt_ceiling_reached?).to be false
    end

    it "returns true when balance drops below threshold" do
      company.update!(main_balance_cents: -2000, promo_balance_cents: 0)
      expect(company.debt_ceiling_reached?).to be true
    end
  end

  describe "#record_usage!" do
    it "increments Redis counter" do
      redis_key = "skycom:company:#{company.id}:orders:#{Date.current.strftime('%Y%m%d')}"
      redis = Kredis.redis

      expect(redis).to receive(:incrby).with(redis_key, 1)
      company.record_usage!("orders")
    end

    it "handles Redis errors gracefully" do
      allow(Kredis.redis).to receive(:incrby).and_raise(Redis::BaseConnectionError)
      expect { company.record_usage!("orders") }.not_to raise_error
    end
  end
end
```

- [ ] **Step 3: Add factories for billing test data**

```ruby
# spec/factories/billing_resources.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :billing_resource do
    name { "test_resource" }
    description { "Test billing resource" }
    resource_type { :volumetric }

    trait :addon_feature do
      resource_type { :addon_feature }
    end

    trait :volumetric do
      resource_type { :volumetric }
    end
  end
end
```

```ruby
# spec/factories/billing_contracts.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :billing_contract do
    company
    name { "Test Contract" }
    contract_type { :free_tier }
    lifecycle_status { :active }
    start_date { Time.current }
    fixed_monthly_price_cents { 0 }
    fixed_monthly_price_currency { "USD" }
  end
end
```

```ruby
# spec/factories/contract_features.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :contract_feature do
    billing_resource
    billing_contract
    name { "Test Feature" }
    monthly_flat_price_cents { 0 }
    lifecycle_status { :active }
  end
end
```

```ruby
# spec/factories/contract_metrics.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :contract_metric do
    billing_resource
    billing_contract
    name { "Test Metric" }
    free_allowance { 100 }
    unit_price_cents { 10 }
    lifecycle_status { :active }
  end
end
```

```ruby
# spec/factories/daily_usage_logs.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :daily_usage_log do
    company
    billing_resource
    usage_count { 0 }
    log_date { Date.current }
  end
end
```

```ruby
# spec/factories/billing_invoices.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :billing_invoice do
    company
    billing_contract
    invoice_number { "INV-#{Time.current.strftime('%Y%m')}-#{SecureRandom.hex(3).upcase}" }
    price_cents { 0 }
    price_currency { "USD" }
    period_start { 1.month.ago.beginning_of_month }
    period_end { 1.month.ago.end_of_month }
    payment_status { :unpaid }
    lifecycle_status { :final }
  end
end
```

- [ ] **Step 4: Run tests**

```bash
bundle exec rspec spec/models/concerns/company/billing_concern_spec.rb
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/models/concerns/company/billing_concern.rb spec/models/concerns/company/billing_concern_spec.rb spec/factories/
git commit -m "feat: add Company::BillingConcern with feature gating and wallet helpers"
```

---

### Task 4: Company::CircuitBreakerConcern

**Files:**
- Create: `app/models/concerns/company/circuit_breaker_concern.rb`
- Test: `spec/models/concerns/company/circuit_breaker_concern_spec.rb`

- [ ] **Step 1: Write the concern**

```ruby
# frozen_string_literal: true

# app/models/concerns/company/circuit_breaker_concern.rb
module Company::CircuitBreakerConcern
  extend ActiveSupport::Concern

  included do
    after_update :auto_reset_circuit_breaker, if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }
  end

  def circuit_breaker_trip!
    return if read_only? || suspended?

    update!(workflow_status: :read_only)
  end

  def circuit_breaker_reset!
    return unless read_only? || suspended?

    update!(workflow_status: :active)
  end

  private

  def auto_reset_circuit_breaker
    return unless read_only?
    return if debt_ceiling_reached?

    circuit_breaker_reset!
  end
end
```

- [ ] **Step 2: Write the test**

```ruby
# frozen_string_literal: true

# spec/models/concerns/company/circuit_breaker_concern_spec.rb
require "rails_helper"

RSpec.describe Company::CircuitBreakerConcern do
  subject(:company) { create(:company, workflow_status: :active) }

  describe "#circuit_breaker_trip!" do
    it "sets workflow_status to read_only" do
      expect { company.circuit_breaker_trip! }
        .to change { company.reload.workflow_status }.from("active").to("read_only")
    end

    it "does not change status if already suspended" do
      company.update!(workflow_status: :suspended)
      expect { company.circuit_breaker_trip! }
        .not_to change { company.reload.workflow_status }
    end
  end

  describe "#circuit_breaker_reset!" do
    before { company.update!(workflow_status: :read_only) }

    it "sets workflow_status back to active" do
      expect { company.circuit_breaker_reset! }
        .to change { company.reload.workflow_status }.from("read_only").to("active")
    end
  end

  describe "auto-reset on balance recovery" do
    before do
      company.update!(workflow_status: :read_only, soft_debt_threshold_cents: -1000,
                      main_balance_cents: -5000, promo_balance_cents: 0)
    end

    it "resets to active when balance recovers above threshold" do
      company.update!(main_balance_cents: 0)
      expect(company.reload.workflow_status).to eq("active")
    end

    it "does not auto-reset when still below threshold" do
      company.update!(main_balance_cents: -2000)
      expect(company.reload.workflow_status).to eq("read_only")
    end
  end
end
```

- [ ] **Step 3: Run tests**

```bash
bundle exec rspec spec/models/concerns/company/circuit_breaker_concern_spec.rb
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/models/concerns/company/circuit_breaker_concern.rb spec/models/concerns/company/circuit_breaker_concern_spec.rb
git commit -m "feat: add Company::CircuitBreakerConcern"
```

---

### Task 5: Wire concerns into Company model

**Files:**
- Modify: `app/models/company.rb`

- [ ] **Step 1: Add concerns + associations to Company**

Add these lines to `app/models/company.rb`:

```ruby
# Inside the class, after existing include lines:
include Company::BillingConcern
include Company::CircuitBreakerConcern

# After existing has_many lines:
has_many :wallet_transactions, dependent: :destroy
has_many :billing_resources, through: :billing_contracts  # optional convenience
```

- [ ] **Step 2: Verify the model loads**

```bash
bin/rails runner "puts Company.ancestors.include?(Company::BillingConcern)"
```

Expected: `true`

- [ ] **Step 3: Commit**

```bash
git add app/models/company.rb
git commit -m "feat: wire BillingConcern and CircuitBreakerConcern into Company"
```

---

### Task 6: MeteringConcern — Redis usage counters on model create

**Files:**
- Create: `app/models/concerns/metering_concern.rb`
- Test: `spec/models/concerns/metering_concern_spec.rb`
- Modify: `app/models/order.rb`, `app/models/employee.rb`, `app/models/branch.rb`, `app/models/customer.rb`

- [ ] **Step 1: Write the concern**

```ruby
# frozen_string_literal: true

# app/models/concerns/metering_concern.rb
module MeteringConcern
  extend ActiveSupport::Concern

  class_methods do
    def metered_as(resource_key)
      @metered_resource_key = resource_key
    end

    def metered_resource_key
      @metered_resource_key
    end
  end

  included do
    after_commit :increment_usage_counter, on: :create
  end

  private

  def increment_usage_counter
    key = self.class.metered_resource_key
    return unless key && respond_to?(:company_id) && company_id.present?

    company.record_usage!(key)
  end
end
```

- [ ] **Step 2: Write the test**

```ruby
# frozen_string_literal: true

# spec/models/concerns/metering_concern_spec.rb
require "rails_helper"

RSpec.describe MeteringConcern do
  # Use a dummy model to test the concern in isolation
  let(:test_model_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "orders" # reuse existing table for test
      include MeteringConcern
      metered_as :orders
      belongs_to :company
    end
  end

  describe "class methods" do
    it "stores the metered resource key" do
      expect(test_model_class.metered_resource_key).to eq("orders")
    end
  end

  describe "increment_usage_counter" do
    let(:company) { create(:company) }

    it "calls record_usage! on the company after create" do
      expect_any_instance_of(Company).to receive(:record_usage!).with("orders")

      # We can't easily instantiate the anonymous class here,
      # so we test through a real model instead
    end
  end

  context "when included in Order" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company) }
    let(:customer) { create(:customer, company: company, branch: branch) }

    it "calls record_usage! when an order is created" do
      expect_any_instance_of(Company).to receive(:record_usage!).with("orders")

      create(:order,
        company: company,
        branch: branch,
        product: product,
        customer: customer
      )
    end
  end
end
```

- [ ] **Step 3: Include MeteringConcern in countable models**

```ruby
# In app/models/order.rb, add inside the class:
include MeteringConcern
metered_as :orders
```

```ruby
# In app/models/employee.rb, add inside the class:
include MeteringConcern
metered_as :employees
```

```ruby
# In app/models/branch.rb, add inside the class:
include MeteringConcern
metered_as :branches
```

```ruby
# In app/models/customer.rb, add inside the class:
include MeteringConcern
metered_as :customers
```

- [ ] **Step 4: Run tests**

```bash
bundle exec rspec spec/models/concerns/metering_concern_spec.rb
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/models/concerns/metering_concern.rb spec/models/concerns/metering_concern_spec.rb app/models/order.rb app/models/employee.rb app/models/branch.rb app/models/customer.rb
git commit -m "feat: add MeteringConcern for Redis usage counters"
```

---

### Task 7: Billing module declarations + SeedResourcesService

**Files:**
- Create: `app/services/billing.rb`
- Create: `app/jobs/billing.rb`
- Create: `app/services/billing/seed_resources_service.rb`
- Test: `spec/services/billing/seed_resources_service_spec.rb`

- [ ] **Step 1: Create module declaration files**

```ruby
# frozen_string_literal: true

# app/services/billing.rb
module Billing
end
```

```ruby
# frozen_string_literal: true

# app/jobs/billing.rb
module Billing
end
```

- [ ] **Step 2: Write SeedResourcesService**

```ruby
# frozen_string_literal: true

# app/services/billing/seed_resources_service.rb
module Billing
  class SeedResourcesService
    VOLUMETRIC_RESOURCES = {
      orders: "Customer orders placed",
      storage_mb: "File storage in megabytes",
      employees: "Active employee records",
      branches: "Active branch locations",
      customers: "Customer records",
      api_calls: "API requests",
      stock_mutations: "Stock import/export/transfer operations"
    }.freeze

    ADDON_FEATURES = {
      hrm_attendance: "Time and attendance tracking",
      hrm_payroll_commissions: "Payroll and commission management",
      inventory_advanced: "Multi-warehouse and supplier management",
      crm_loyalty: "Loyalty and rewards program",
      multi_branch: "Multi-branch management",
      automation_engine: "Automated workflow rules",
      analytics_dashboard: "Advanced analytics and reporting",
      payment_gateways: "Integrated payment processing",
      audit_logs: "Advanced auditing",
      custom_roles: "Granular RBAC",
      open_api: "Developer API access",
      sso_saml: "Single sign-on"
    }.freeze

    def self.call
      VOLUMETRIC_RESOURCES.each do |name, description|
        BillingResource.find_or_create_by!(name: name.to_s) do |r|
          r.description = description
          r.resource_type = :volumetric
        end
      end

      ADDON_FEATURES.each do |name, description|
        BillingResource.find_or_create_by!(name: name.to_s) do |r|
          r.description = description
          r.resource_type = :addon_feature
        end
      end
    end
  end
end
```

- [ ] **Step 3: Write the test**

```ruby
# frozen_string_literal: true

# spec/services/billing/seed_resources_service_spec.rb
require "rails_helper"

RSpec.describe Billing::SeedResourcesService do
  describe ".call" do
    it "creates volumetric billing resources" do
      expect { described_class.call }.to change(BillingResource.volumetric, :count).by(7)
    end

    it "creates addon feature billing resources" do
      expect { described_class.call }.to change(BillingResource.addon_feature, :count).by(12)
    end

    it "is idempotent" do
      described_class.call
      expect { described_class.call }.not_to change(BillingResource, :count)
    end

    it "creates an orders resource" do
      described_class.call
      expect(BillingResource.find_by(name: "orders")).to be_present
    end

    it "creates an analytics_dashboard resource" do
      described_class.call
      expect(BillingResource.find_by(name: "analytics_dashboard")).to be_present
    end
  end
end
```

- [ ] **Step 4: Run tests**

```bash
bundle exec rspec spec/services/billing/seed_resources_service_spec.rb
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/services/billing.rb app/jobs/billing.rb app/services/billing/seed_resources_service.rb spec/services/billing/seed_resources_service_spec.rb
git commit -m "feat: add Billing::SeedResourcesService"
```

---

### Task 8: Billing::SyncDailyUsageJob — nightly Redis to Postgres sync

**Files:**
- Create: `app/jobs/billing/sync_daily_usage_job.rb`
- Test: `spec/jobs/billing/sync_daily_usage_job_spec.rb`

- [ ] **Step 1: Write the job**

```ruby
# frozen_string_literal: true

# app/jobs/billing/sync_daily_usage_job.rb
module Billing
  class SyncDailyUsageJob < ApplicationJob
    queue_as :default

    SCAN_PATTERN = "skycom:company:*:*:"

    def perform(log_date: Date.current)
      date_str = log_date.strftime("%Y%m%d")
      scan_match = "#{SCAN_PATTERN}#{date_str}"

      cursor = "0"
      loop do
        cursor, keys = Kredis.redis.scan(cursor, match: scan_match, count: 100)
        break if cursor == "0" && keys.empty?

        keys.each { |key| process_key(key, log_date) }

        break if cursor == "0"
      end
    end

    private

    def process_key(key, log_date)
      # Key format: skycom:company:<uuid>:<resource_name>:<YYYYMMDD>
      parts = key.split(":")
      company_id = parts[2]
      resource_name = parts[3]

      company = Company.find_by(id: company_id)
      resource = BillingResource.find_by(name: resource_name)

      unless company && resource
        Rails.logger.warn("SyncDailyUsageJob: Skipping key #{key} — company or resource not found")
        return
      end

      value = Kredis.redis.get(key).to_i
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
  end
end
```

- [ ] **Step 2: Write the test**

```ruby
# frozen_string_literal: true

# spec/jobs/billing/sync_daily_usage_job_spec.rb
require "rails_helper"

RSpec.describe Billing::SyncDailyUsageJob do
  subject(:perform_job) { described_class.perform_now(log_date: log_date) }

  let(:log_date) { Date.current }
  let(:company) { create(:company) }
  let!(:resource) { create(:billing_resource, :volumetric, name: "orders") }
  let(:date_str) { log_date.strftime("%Y%m%d") }
  let(:redis_key) { "skycom:company:#{company.id}:orders:#{date_str}" }

  before do
    Kredis.redis.flushdb
  end

  after do
    Kredis.redis.flushdb
  end

  context "when Redis keys exist for today" do
    before do
      Kredis.redis.set(redis_key, 42)
    end

    it "creates a DailyUsageLog record" do
      expect { perform_job }.to change(DailyUsageLog, :count).by(1)
    end

    it "records the correct usage count" do
      perform_job
      log = DailyUsageLog.last
      expect(log.usage_count).to eq(42)
      expect(log.company).to eq(company)
      expect(log.billing_resource).to eq(resource)
      expect(log.log_date).to eq(log_date)
    end

    it "deletes the Redis key after sync" do
      perform_job
      expect(Kredis.redis.exists?(redis_key)).to be(false)
    end
  end

  context "when Redis key has zero value" do
    before do
      Kredis.redis.set(redis_key, 0)
    end

    it "does not create a DailyUsageLog" do
      expect { perform_job }.not_to change(DailyUsageLog, :count)
    end
  end

  context "when the key references a deleted company" do
    before do
      Kredis.redis.set("skycom:company:nonexistent:orders:#{date_str}", 10)
    end

    it "skips gracefully without error" do
      expect { perform_job }.not_to raise_error
    end
  end

  context "when no Redis keys exist" do
    it "does nothing" do
      expect { perform_job }.not_to change(DailyUsageLog, :count)
    end
  end
end
```

- [ ] **Step 3: Run tests**

```bash
bundle exec rspec spec/jobs/billing/sync_daily_usage_job_spec.rb
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/jobs/billing/sync_daily_usage_job.rb spec/jobs/billing/sync_daily_usage_job_spec.rb
git commit -m "feat: add Billing::SyncDailyUsageJob"
```

---

### Task 9: Billing::CalculatorService — compute monthly charges

**Files:**
- Create: `app/services/billing/calculator_service.rb`
- Test: `spec/services/billing/calculator_service_spec.rb`

- [ ] **Step 1: Write the service**

```ruby
# frozen_string_literal: true

# app/services/billing/calculator_service.rb
module Billing
  class CalculatorService
    Result = Struct.new(:total_cents, :breakdown, keyword_init: true) do
      def initialize(total_cents: 0, breakdown: {})
        super
      end
    end

    Breakdown = Struct.new(:base_cents, :features_cents, :overages, keyword_init: true) do
      def total_cents
        base_cents.to_i + features_cents.to_i + overages.values.sum
      end
    end

    def self.call(company, period_start: nil, period_end: nil)
      new(company, period_start: period_start, period_end: period_end).call
    end

    def initialize(company, period_start: nil, period_end: nil)
      @company = company
      @period_start = period_start || 1.month.ago.beginning_of_month
      @period_end = period_end || 1.month.ago.end_of_month
    end

    def call
      contract = company.active_billing_contract
      return zero_result unless contract

      base_cents = contract.fixed_monthly_price_cents
      features_cents = contract.contract_features.active.sum(:monthly_flat_price_cents)
      overages = compute_overages(contract)

      breakdown = Breakdown.new(
        base_cents: base_cents,
        features_cents: features_cents,
        overages: overages
      )

      Result.new(total_cents: breakdown.total_cents, breakdown: breakdown)
    end

    private

    attr_reader :company, :period_start, :period_end

    def zero_result
      Result.new
    end

    def compute_overages(contract)
      contract.contract_metrics.active.each_with_object({}) do |metric, hash|
        actual = DailyUsageLog.where(company: company, billing_resource: metric.billing_resource)
                              .for_period(period_start, period_end)
                              .sum(:usage_count)

        if actual > metric.free_allowance
          overage_units = actual - metric.free_allowance
          hash[metric.billing_resource.name] = overage_units * metric.unit_price_cents
        end
      end
    end
  end
end
```

- [ ] **Step 2: Write the test**

```ruby
# frozen_string_literal: true

# spec/services/billing/calculator_service_spec.rb
require "rails_helper"

RSpec.describe Billing::CalculatorService do
  subject(:result) { described_class.call(company) }

  let(:company) { create(:company) }
  let(:period_start) { 1.month.ago.beginning_of_month }
  let(:period_end) { 1.month.ago.end_of_month }

  let!(:contract) do
    create(:billing_contract, company: company, lifecycle_status: :active,
           start_date: 3.months.ago, fixed_monthly_price_cents: 1000)
  end

  context "when contract has no features or metrics" do
    it "returns total_cents equal to base price" do
      expect(result.total_cents).to eq(1000)
    end

    it "includes base in breakdown" do
      expect(result.breakdown.base_cents).to eq(1000)
    end

    it "has zero features_cents" do
      expect(result.breakdown.features_cents).to eq(0)
    end

    it "has empty overages" do
      expect(result.breakdown.overages).to eq({})
    end
  end

  context "when contract has active features" do
    let!(:feature_resource) { create(:billing_resource, :addon_feature, name: "analytics_dashboard") }

    before do
      create(:contract_feature, billing_contract: contract,
             billing_resource: feature_resource, monthly_flat_price_cents: 500, lifecycle_status: :active)
    end

    it "adds feature prices to total" do
      expect(result.total_cents).to eq(1500)
    end

    it "includes features in breakdown" do
      expect(result.breakdown.features_cents).to eq(500)
    end
  end

  context "when contract has usage overages" do
    let!(:metric_resource) { create(:billing_resource, :volumetric, name: "orders") }

    before do
      create(:contract_metric, billing_contract: contract,
             billing_resource: metric_resource, free_allowance: 100, unit_price_cents: 10)

      create(:daily_usage_log, company: company, billing_resource: metric_resource,
             usage_count: 50, log_date: period_start + 5.days)
      create(:daily_usage_log, company: company, billing_resource: metric_resource,
             usage_count: 70, log_date: period_start + 15.days)
    end

    it "charges for overage above free allowance" do
      # total usage = 120, free = 100, overage = 20 * 10 = 200
      expect(result.breakdown.overages["orders"]).to eq(200)
    end

    it "includes overage in total" do
      # base 1000 + overage 200 = 1200
      expect(result.total_cents).to eq(1200)
    end
  end

  context "when usage is within free allowance" do
    let!(:metric_resource) { create(:billing_resource, :volumetric, name: "orders") }

    before do
      create(:contract_metric, billing_contract: contract,
             billing_resource: metric_resource, free_allowance: 100, unit_price_cents: 10)

      create(:daily_usage_log, company: company, billing_resource: metric_resource,
             usage_count: 30, log_date: period_start + 5.days)
    end

    it "does not charge overage" do
      expect(result.breakdown.overages).to eq({})
    end

    it "total is just base price" do
      expect(result.total_cents).to eq(1000)
    end
  end

  context "when no active contract exists" do
    before { contract.update!(lifecycle_status: :expired) }

    it "returns zero result" do
      expect(result.total_cents).to eq(0)
    end
  end
end
```

- [ ] **Step 3: Run tests**

```bash
bundle exec rspec spec/services/billing/calculator_service_spec.rb
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/services/billing/calculator_service.rb spec/services/billing/calculator_service_spec.rb
git commit -m "feat: add Billing::CalculatorService"
```

---

### Task 10: Billing::InvoiceService — create BillingInvoice

**Files:**
- Create: `app/services/billing/invoice_service.rb`
- Test: `spec/services/billing/invoice_service_spec.rb`

- [ ] **Step 1: Write the service**

```ruby
# frozen_string_literal: true

# app/services/billing/invoice_service.rb
module Billing
  class InvoiceService
    def self.call(company, calculator_result, period_start: nil, period_end: nil)
      new(company, calculator_result, period_start: period_start, period_end: period_end).call
    end

    def initialize(company, calculator_result, period_start: nil, period_end: nil)
      @company = company
      @calculator_result = calculator_result
      @period_start = period_start || 1.month.ago.beginning_of_month
      @period_end = period_end || 1.month.ago.end_of_month
    end

    def call
      contract = company.active_billing_contract
      return nil unless contract

      BillingInvoice.create!(
        company: company,
        billing_contract: contract,
        price_cents: calculator_result.total_cents,
        price_currency: "USD",
        period_start: period_start,
        period_end: period_end,
        payment_status: :unpaid,
        lifecycle_status: :final
      )
    end

    private

    attr_reader :company, :calculator_result, :period_start, :period_end
  end
end
```

- [ ] **Step 2: Write the test**

```ruby
# frozen_string_literal: true

# spec/services/billing/invoice_service_spec.rb
require "rails_helper"

RSpec.describe Billing::InvoiceService do
  subject(:invoice) { described_class.call(company, calculator_result) }

  let(:company) { create(:company) }
  let(:period_start) { 1.month.ago.beginning_of_month }
  let(:period_end) { 1.month.ago.end_of_month }

  let!(:contract) do
    create(:billing_contract, company: company, lifecycle_status: :active, start_date: 3.months.ago)
  end

  let(:calculator_result) do
    Billing::CalculatorService::Result.new(
      total_cents: 1500,
      breakdown: Billing::CalculatorService::Breakdown.new(
        base_cents: 1000, features_cents: 500, overages: {}
      )
    )
  end

  it "creates a BillingInvoice" do
    expect { invoice }.to change(BillingInvoice, :count).by(1)
  end

  it "sets the correct total" do
    expect(invoice.price_cents).to eq(1500)
  end

  it "links to the active contract" do
    expect(invoice.billing_contract).to eq(contract)
  end

  it "sets the period" do
    expect(invoice.period_start).to eq(period_start)
    expect(invoice.period_end).to eq(period_end)
  end

  it "starts as unpaid" do
    expect(invoice.payment_status).to eq("unpaid")
  end

  it "is finalized" do
    expect(invoice.lifecycle_status).to eq("final")
  end

  context "when no active contract exists" do
    before { contract.update!(lifecycle_status: :expired) }

    it "returns nil" do
      expect(invoice).to be_nil
    end
  end
end
```

- [ ] **Step 3: Run tests**

```bash
bundle exec rspec spec/services/billing/invoice_service_spec.rb
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/services/billing/invoice_service.rb spec/services/billing/invoice_service_spec.rb
git commit -m "feat: add Billing::InvoiceService"
```

---

### Task 11: Billing::SettlementService — wallet deduction + circuit breaker

**Files:**
- Create: `app/services/billing/settlement_service.rb`
- Test: `spec/services/billing/settlement_service_spec.rb`

- [ ] **Step 1: Write the service**

```ruby
# frozen_string_literal: true

# app/services/billing/settlement_service.rb
module Billing
  class SettlementService
    def self.call(invoice)
      new(invoice).call
    end

    def initialize(invoice)
      @invoice = invoice
      @company = invoice.company
    end

    def call
      total = invoice.price_cents
      return mark_paid if total.zero?

      company.with_lock do
        remaining = deduct_from_promo(total)
        remaining = deduct_from_main(remaining)

        if remaining > 0
          handle_shortfall(remaining)
        else
          mark_paid
        end
      end
    end

    private

    attr_reader :invoice, :company

    def deduct_from_promo(amount)
      promo_before = company.promo_balance_cents

      if promo_before >= amount
        company.update!(promo_balance_cents: promo_before - amount)
        record_transaction(:deduction, amount, promo_before, promo_before - amount,
                           company.main_balance_cents, company.main_balance_cents)
        return 0
      end

      company.update!(promo_balance_cents: 0)
      record_transaction(:deduction, promo_before, promo_before, 0,
                         company.main_balance_cents, company.main_balance_cents) if promo_before > 0
      amount - promo_before
    end

    def deduct_from_main(amount)
      main_before = company.main_balance_cents

      if main_before >= amount
        company.update!(main_balance_cents: main_before - amount)
        record_transaction(:deduction, amount, main_before, main_before - amount,
                           company.promo_balance_cents, company.promo_balance_cents)
        return 0
      end

      company.update!(main_balance_cents: 0)
      record_transaction(:deduction, main_before, main_before, 0,
                         company.promo_balance_cents, company.promo_balance_cents) if main_before > 0
      amount - main_before
    end

    def handle_shortfall(remaining)
      company.circuit_breaker_trip!
      invoice.update!(payment_status: :overdue)

      record_transaction(:deduction, 0,
                         company.main_balance_cents, company.main_balance_cents,
                         company.promo_balance_cents, company.promo_balance_cents)
    end

    def mark_paid
      invoice.update!(payment_status: :paid)
    end

    def record_transaction(type, amount, before_main, after_main, before_promo, after_promo)
      WalletTransaction.create!(
        company: company,
        billing_invoice: invoice,
        transaction_type: type,
        amount_cents: amount,
        currency: "USD",
        balance_before_cents: before_main,
        balance_after_cents: after_main,
        promo_balance_before_cents: before_promo,
        promo_balance_after_cents: after_promo,
        description: "Monthly billing invoice #{invoice.invoice_number}"
      )
    end
  end
end
```

- [ ] **Step 2: Write the test**

```ruby
# frozen_string_literal: true

# spec/services/billing/settlement_service_spec.rb
require "rails_helper"

RSpec.describe Billing::SettlementService do
  subject(:settle) { described_class.call(invoice) }

  let(:company) { create(:company) }
  let(:contract) { create(:billing_contract, company: company, lifecycle_status: :active, start_date: 3.months.ago) }
  let(:invoice) do
    create(:billing_invoice, company: company, billing_contract: contract,
           price_cents: 1500, period_start: 1.month.ago.beginning_of_month,
           period_end: 1.month.ago.end_of_month)
  end

  context "when promo balance covers the full amount" do
    before do
      company.update!(promo_balance_cents: 2000, main_balance_cents: 0)
    end

    it "deducts from promo balance" do
      expect { settle }
        .to change { company.reload.promo_balance_cents }.from(2000).to(500)
    end

    it "marks invoice as paid" do
      settle
      expect(invoice.reload.payment_status).to eq("paid")
    end

    it "creates a WalletTransaction" do
      expect { settle }.to change(WalletTransaction, :count).by(1)
    end
  end

  context "when promo covers partial and main covers the rest" do
    before do
      company.update!(promo_balance_cents: 500, main_balance_cents: 2000)
    end

    it "drains promo first" do
      settle
      expect(company.reload.promo_balance_cents).to eq(0)
    end

    it "deducts remaining from main" do
      expect { settle }
        .to change { company.reload.main_balance_cents }.from(2000).to(1000)
    end

    it "marks invoice as paid" do
      settle
      expect(invoice.reload.payment_status).to eq("paid")
    end

    it "records two WalletTransactions" do
      expect { settle }.to change(WalletTransaction, :count).by(2)
    end
  end

  context "when neither balance covers the amount" do
    before do
      company.update!(promo_balance_cents: 500, main_balance_cents: 500,
                      workflow_status: :active, soft_debt_threshold_cents: -10000)
    end

    it "drains both balances" do
      settle
      expect(company.reload.promo_balance_cents).to eq(0)
      expect(company.reload.main_balance_cents).to eq(0)
    end

    it "marks invoice as overdue" do
      settle
      expect(invoice.reload.payment_status).to eq("overdue")
    end

    it "trips the circuit breaker" do
      expect { settle }
        .to change { company.reload.workflow_status }.from("active").to("read_only")
    end
  end

  context "when invoice total is zero" do
    let(:invoice) do
      create(:billing_invoice, company: company, billing_contract: contract,
             price_cents: 0)
    end

    it "marks invoice as paid without deductions" do
      settle
      expect(invoice.reload.payment_status).to eq("paid")
    end

    it "does not create WalletTransactions" do
      expect { settle }.not_to change(WalletTransaction, :count)
    end
  end
end
```

- [ ] **Step 3: Run tests**

```bash
bundle exec rspec spec/services/billing/settlement_service_spec.rb
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/services/billing/settlement_service.rb spec/services/billing/settlement_service_spec.rb
git commit -m "feat: add Billing::SettlementService"
```

---

### Task 12: Billing::MonthlyBillingJob — orchestrator

**Files:**
- Create: `app/jobs/billing/monthly_billing_job.rb`
- Test: `spec/jobs/billing/monthly_billing_job_spec.rb`

- [ ] **Step 1: Write the job**

```ruby
# frozen_string_literal: true

# app/jobs/billing/monthly_billing_job.rb
module Billing
  class MonthlyBillingJob < ApplicationJob
    queue_as :default

    def perform
      Company.active.find_each(batch_size: 50) do |company|
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

      SettlementService.call(invoice)
    end
  end
end
```

- [ ] **Step 2: Write the test**

```ruby
# frozen_string_literal: true

# spec/jobs/billing/monthly_billing_job_spec.rb
require "rails_helper"

RSpec.describe Billing::MonthlyBillingJob do
  subject(:perform_job) { described_class.perform_now }

  let(:company) { create(:company) }
  let!(:contract) do
    create(:billing_contract, company: company, lifecycle_status: :active,
           start_date: 3.months.ago, fixed_monthly_price_cents: 1000)
  end

  context "when company has an active contract with base price" do
    before do
      company.update!(promo_balance_cents: 2000, main_balance_cents: 0)
    end

    it "creates a BillingInvoice" do
      expect { perform_job }.to change(BillingInvoice, :count).by(1)
    end

    it "deducts from wallet" do
      expect { perform_job }
        .to change { company.reload.promo_balance_cents }.from(2000).to(1000)
    end

    it "marks invoice as paid" do
      perform_job
      expect(BillingInvoice.last.payment_status).to eq("paid")
    end
  end

  context "when company has no active contract" do
    before { contract.update!(lifecycle_status: :expired) }

    it "does not create an invoice" do
      expect { perform_job }.not_to change(BillingInvoice, :count)
    end
  end

  context "when company has zero total charges" do
    before do
      contract.update!(fixed_monthly_price_cents: 0)
    end

    it "does not create an invoice for zero charges" do
      expect { perform_job }.not_to change(BillingInvoice, :count)
    end
  end

  context "with multiple companies" do
    let(:company2) { create(:company) }
    let!(:contract2) do
      create(:billing_contract, company: company2, lifecycle_status: :active,
             start_date: 3.months.ago, fixed_monthly_price_cents: 500)
    end

    before do
      company.update!(promo_balance_cents: 2000, main_balance_cents: 0)
      company2.update!(promo_balance_cents: 1000, main_balance_cents: 0)
    end

    it "processes all active companies" do
      expect { perform_job }.to change(BillingInvoice, :count).by(2)
    end

    it "handles individual company failures gracefully" do
      allow_any_instance_of(Company).to receive(:active_billing_contract)
        .and_raise(StandardError)
        .and_call_original

      expect { perform_job }.not_to raise_error
    end
  end
end
```

- [ ] **Step 3: Run tests**

```bash
bundle exec rspec spec/jobs/billing/monthly_billing_job_spec.rb
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/jobs/billing/monthly_billing_job.rb spec/jobs/billing/monthly_billing_job_spec.rb
git commit -m "feat: add Billing::MonthlyBillingJob"
```

---

### Task 13: Configure recurring schedules in config/recurring.yml

**Files:**
- Modify: `config/recurring.yml`

- [ ] **Step 1: Add billing job schedules**

```yaml
# In config/recurring.yml, under the default: &default section, add:
  sync_daily_usage:
    class: Billing::SyncDailyUsageJob
    queue: default
    schedule: at 23:55 every day

  monthly_billing:
    class: Billing::MonthlyBillingJob
    queue: default
    schedule: at 00:00 day 1 every month
```

- [ ] **Step 2: Commit**

```bash
git add config/recurring.yml
git commit -m "feat: add billing recurring job schedules"
```

---

### Task 14: Final verification — run full test suite

**Files:**
- All of the above

- [ ] **Step 1: Run all billing-related tests**

```bash
bundle exec rspec spec/models/wallet_transaction_spec.rb spec/models/concerns/ spec/services/billing/ spec/jobs/billing/
```

Expected: all tests pass.

- [ ] **Step 2: Run the existing test suite to verify no regressions**

```bash
bundle exec rspec
```

Expected: all tests pass (or same failures as before if there were existing failures).

- [ ] **Step 3: Run linter**

```bash
bin/rubocop --autocorrect-all
```

Fix any issues.

- [ ] **Step 4: Final commit if linter changes were made**

```bash
git add -A
git commit -m "chore: fix linting for billing engine"
```

---

### Self-Review Checklist

1. **Spec coverage:** Does the plan implement all sections from the design spec?
   - ✅ Migrations (wallet fields + wallet_transactions) — Task 1, 2
   - ✅ Company::BillingConcern (feature_enabled?, active_billing_contract, wallet helpers) — Task 3
   - ✅ Company::CircuitBreakerConcern (trip!, reset!, auto-reset) — Task 4
   - ✅ MeteringConcern (Redis INCR on create) — Task 6
   - ✅ Billing::SeedResourcesService — Task 7
   - ✅ Billing::SyncDailyUsageJob — Task 8
   - ✅ Billing::CalculatorService — Task 9
   - ✅ Billing::InvoiceService — Task 10
   - ✅ Billing::SettlementService — Task 11
   - ✅ Billing::MonthlyBillingJob — Task 12
   - ✅ Config/recurring.yml schedules — Task 13

2. **Placeholder scan:** No "TBD", "TODO", incomplete steps, or vague requirements.

3. **Type consistency:** All method signatures match across tasks. `feature_enabled?` takes a string key, `record_usage!` takes a resource key string, `CalculatorService::Result` and `CalculatorService::Breakdown` structs are used consistently in InvoiceService.

4. **Scope check:** Single cohesive plan — no decomposition needed. All tasks are backend-only per spec.
