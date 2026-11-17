# spec/models/erp_domain_rules_spec.rb
#
# Behavioural rules for the ERP schema wave that are cheap to prove without a
# seeded tenant: the ledger's double-entry invariant, date windows, money
# arithmetic and the "exactly one subject" guards.
require "rails_helper"

RSpec.describe "ERP domain rules" do
  def uuid = SecureRandom.uuid

  describe JournalLine do
    it "accepts a debit-only line" do
      line = described_class.new(debit_cents: 500, credit_cents: 0)
      line.valid?

      expect(line.errors[:base]).to eq([])
    end

    it "rejects a line that debits and credits at once" do
      line = described_class.new(debit_cents: 500, credit_cents: 500)
      line.valid?

      expect(line.errors[:base]).to include("must debit or credit exactly one side")
    end

    it "rejects a line with no amount on either side" do
      line = described_class.new(debit_cents: 0, credit_cents: 0)
      line.valid?

      expect(line.errors[:base]).to include("must debit or credit exactly one side")
    end

    it "reports a signed amount for summing a trial balance" do
      expect(described_class.new(debit_cents: 700).signed_amount_cents).to eq(700)
      expect(described_class.new(credit_cents: 700).signed_amount_cents).to eq(-700)
    end
  end

  describe JournalEntry do
    it "is balanced when debits equal credits" do
      entry = described_class.new
      entry.journal_lines.build(debit_cents: 1_000)
      entry.journal_lines.build(credit_cents: 1_000)

      expect(entry).to be_balanced
    end

    it "is unbalanced when the legs differ" do
      entry = described_class.new
      entry.journal_lines.build(debit_cents: 1_000)
      entry.journal_lines.build(credit_cents: 900)

      expect(entry).not_to be_balanced
    end
  end

  describe FiscalPeriod do
    it "rejects an end date before the start date" do
      period = described_class.new(starts_on: Date.new(2026, 2, 1), ends_on: Date.new(2026, 1, 1))
      period.valid?

      expect(period.errors[:ends_on]).to include("must be on or after the start date")
    end

    it "accepts a same-day period" do
      period = described_class.new(starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 1, 1))
      period.valid?

      expect(period.errors[:ends_on]).to eq([])
    end

    it "answers whether a date falls inside the period" do
      period = described_class.new(starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 1, 31))

      expect(period.covers?(Date.new(2026, 1, 15))).to be(true)
      expect(period.covers?(Date.new(2026, 2, 1))).to be(false)
    end
  end

  describe ExchangeRate do
    it "rejects a rate whose two currencies are the same" do
      rate = described_class.new(base_currency: :usd, quote_currency: :usd, rate: 1, effective_on: Date.current)
      rate.valid?

      expect(rate.errors[:quote_currency]).to include("must differ from the base currency")
    end

    it "accepts a real pair" do
      rate = described_class.new(base_currency: :usd, quote_currency: :vnd, rate: 25_000, effective_on: Date.current)
      rate.valid?

      expect(rate.errors[:quote_currency]).to eq([])
    end
  end

  describe TaxCode do
    it "converts basis points to a rate" do
      expect(described_class.new(rate_bp: 850).rate).to eq(0.085)
    end

    it "calculates tax on integer cents" do
      expect(described_class.new(rate_bp: 1_000).tax_for_cents(12_345)).to eq(1_235)
    end
  end

  describe FixedAsset do
    it "spreads depreciable cost across the useful life" do
      asset = described_class.new(cost_cents: 120_000, salvage_cents: 0, useful_life_months: 12)

      expect(asset.monthly_depreciation_cents).to eq(10_000)
    end

    it "never depreciates below salvage value" do
      asset = described_class.new(cost_cents: 100_000, salvage_cents: 150_000, useful_life_months: 12)

      expect(asset.depreciable_cents).to eq(0)
    end
  end

  describe PaymentTerm do
    it "derives the due date from net days" do
      term = described_class.new(net_days: 30)

      expect(term.due_date_for(Date.new(2026, 1, 1))).to eq(Date.new(2026, 1, 31))
    end

    it "has no discount deadline when no discount is offered" do
      expect(described_class.new(net_days: 30).discount_deadline_for(Date.new(2026, 1, 1))).to be_nil
    end
  end

  describe SignatureRequest do
    it "rejects a request with two subjects" do
      request = described_class.new(document_id: uuid, stored_file_id: uuid)
      request.valid?

      expect(request.errors[:base]).to include("must reference exactly one document or stored file")
    end

    it "accepts a request with one subject" do
      request = described_class.new(document_id: uuid)
      request.valid?

      expect(request.errors[:base]).to eq([])
    end
  end

  describe PriceListItem do
    it "rejects a line with both a product and a service" do
      item = described_class.new(product_id: uuid, service_id: uuid)
      item.valid?

      expect(item.errors[:base]).to include("must reference exactly one product or service")
    end
  end

  describe ProductBundleComponent do
    it "refuses to make a bundle its own component" do
      product_id = uuid
      bundle = ProductBundle.new(product_id: product_id)
      component = described_class.new(product_bundle: bundle, component_product_id: product_id)
      component.valid?

      expect(component.errors[:component_product]).to include("cannot be the bundle itself")
    end
  end

  describe CreditProfile do
    it "treats a zero limit as unlimited" do
      profile = described_class.new(limit_cents: 0)

      expect(profile.exceeded_by?(5_000_000)).to be(false)
    end

    it "flags a balance above the limit" do
      profile = described_class.new(limit_cents: 10_000)

      expect(profile.exceeded_by?(10_001)).to be(true)
    end
  end

  describe CommissionTier do
    it "covers amounts inside the bracket" do
      tier = described_class.new(from_cents: 1_000, to_cents: 5_000)

      expect(tier.covers_cents?(1_000)).to be(true)
      expect(tier.covers_cents?(4_999)).to be(true)
      expect(tier.covers_cents?(5_000)).to be(false)
    end

    it "treats an open upper bound as unlimited" do
      tier = described_class.new(from_cents: 5_000, to_cents: nil)

      expect(tier.covers_cents?(99_000_000)).to be(true)
    end
  end

  describe ReorderRule do
    it "triggers at or below minimum plus safety stock" do
      rule = described_class.new(min_quantity: 10, safety_stock: 5, max_quantity: 50)

      expect(rule.below_trigger?(15)).to be(true)
      expect(rule.below_trigger?(16)).to be(false)
    end

    it "suggests enough to reach the maximum" do
      rule = described_class.new(min_quantity: 10, safety_stock: 5, max_quantity: 50)

      expect(rule.suggested_quantity(20)).to eq(30)
      expect(rule.suggested_quantity(60)).to eq(0)
    end
  end

  describe PickTask do
    it "detects a short pick" do
      expect(described_class.new(quantity: 5, picked_quantity: 4)).to be_short_picked
      expect(described_class.new(quantity: 5, picked_quantity: 5)).not_to be_short_picked
    end
  end

  describe MaintenancePlan do
    it "requires a day interval or a usage interval" do
      plan = described_class.new(name: "Quarterly service")
      plan.valid?

      expect(plan.errors[:base]).to include("requires an interval in days or in usage units")
    end

    it "accepts a day interval" do
      plan = described_class.new(name: "Quarterly service", interval_days: 90)
      plan.valid?

      expect(plan.errors[:base]).to eq([])
    end
  end

  describe EmployeeManagerAppointment do
    it "refuses to make an employee their own manager" do
      id = uuid
      appointment = described_class.new(employee_id: id, manager_employee_id: id)
      appointment.valid?

      expect(appointment.errors[:manager_employee]).to include("cannot be the employee themselves")
    end
  end

  describe TaskDependency do
    it "refuses a task that depends on itself" do
      id = uuid
      dependency = described_class.new(predecessor_task_id: id, successor_task_id: id)
      dependency.valid?

      expect(dependency.errors[:successor_task]).to include("cannot depend on itself")
    end
  end

  describe PurchaseParentAppointment do
    it "refuses a document that is its own parent" do
      id = uuid
      link = described_class.new(purchase_id: id, related_purchase_id: id)
      link.valid?

      expect(link.errors[:related_purchase]).to include("cannot be the same document")
    end
  end

  describe CompanyCompanyAppointment do
    it "refuses a company that owns itself" do
      id = uuid
      link = described_class.new(parent_company_id: id, child_company_id: id)
      link.valid?

      expect(link.errors[:child_company]).to include("cannot be the same company")
    end
  end

  describe NetworkPolicy do
    it "rejects a value that is not an IP or CIDR block" do
      policy = described_class.new(cidr: "not-an-ip")
      policy.valid?

      expect(policy.errors[:cidr]).to include("must be a valid IP address or CIDR block")
    end

    it "accepts a CIDR block" do
      policy = described_class.new(cidr: "10.0.0.0/8")
      policy.valid?

      expect(policy.errors[:cidr]).to eq([])
    end
  end

  describe DataSubjectRequest do
    it "rejects a request that names two data subjects" do
      request = described_class.new(customer_id: uuid, employee_id: uuid)
      request.valid?

      expect(request.errors[:base]).to include("must reference exactly one data subject")
    end
  end

  describe DataRetentionPolicy do
    it "computes the cutoff from the retention window" do
      policy = described_class.new(retention_days: 30)

      expect(policy.cutoff_date).to eq(Date.current - 30.days)
    end
  end

  describe CompanyEntitlement do
    it "is inactive once expired" do
      expect(described_class.new(is_enabled: true, expires_at: 1.day.ago)).not_to be_active
      expect(described_class.new(is_enabled: true, expires_at: 1.day.from_now)).to be_active
    end

    it "is inactive when switched off even without an expiry" do
      expect(described_class.new(is_enabled: false)).not_to be_active
    end
  end

  describe ApiKey do
    it "is inactive once revoked" do
      expect(described_class.new(name: "key", token_digest: "digest", revoked_at: Time.current)).not_to be_active
    end

    it "is active while unrevoked and unexpired" do
      expect(described_class.new(name: "key", token_digest: "digest")).to be_active
    end
  end

  describe WebhookEndpoint do
    it "matches only subscribed event keys" do
      endpoint = described_class.new(url: "https://example.test/hook", event_keys: [ "invoice.paid" ])

      expect(endpoint.subscribed_to?("invoice.paid")).to be(true)
      expect(endpoint.subscribed_to?("stock.low")).to be(false)
    end
  end

  describe CourseEnrollment do
    it "reports expiry from the certification date" do
      expect(described_class.new(expires_on: Date.current - 1)).to be_expired
      expect(described_class.new(expires_on: Date.current + 1)).not_to be_expired
    end
  end

  describe StockLot do
    it "reports expiry from the lot date" do
      expect(described_class.new(expires_on: Date.current - 1)).to be_expired
    end
  end

  describe BomLine do
    it "scales component quantity by the production run and scrap rate" do
      line = described_class.new(quantity: 2, scrap_bp: 0)

      expect(line.required_quantity_for(10)).to eq(20)
    end

    it "adds the scrap allowance on top" do
      line = described_class.new(quantity: 100, scrap_bp: 500)

      expect(line.required_quantity_for(1).to_d).to eq(105)
    end
  end

  describe ProductionOperation do
    it "adds setup time to per-unit run time" do
      operation = described_class.new(setup_minutes: 15, run_minutes_per_unit: 2)

      expect(operation.planned_minutes_for(10)).to eq(35)
    end
  end

  describe QualityCheck do
    it "accepts a measurement inside the bounds" do
      check = described_class.new(min_value: 1, max_value: 5, measured_value: 3)

      expect(check).to be_within_bounds
    end

    it "rejects a measurement outside the bounds" do
      check = described_class.new(min_value: 1, max_value: 5, measured_value: 8)

      expect(check).not_to be_within_bounds
    end
  end

  describe ProductionOrderMaterial do
    it "reports consumption variance against the snapshot" do
      material = described_class.new(required_quantity: 10, consumed_quantity: 12)

      expect(material.variance_quantity).to eq(2)
    end
  end

  describe ProjectBillingTerm do
    it "detects a reached cap only when one is set" do
      expect(described_class.new(cap_cents: 1_000).cap_reached?(1_000)).to be(true)
      expect(described_class.new(cap_cents: nil).cap_reached?(10_000_000)).to be(false)
    end
  end

  describe ProjectTimeEntry do
    it "prices minutes at the snapshotted rate" do
      entry = described_class.new(minutes: 90, rate_cents: 60_000)

      expect(entry.amount_cents).to eq(90_000)
    end
  end
end
