# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::MonthlyBillingJob do
  subject(:perform_job) { described_class.perform_now }

  let(:company) { create(:company, lifecycle_status: :active) }
  # Auto-seeded free-tier contract (active, base=$0); update base price when needed
  let!(:contract) { company.active_billing_contract }

  context "when company has an active contract with base price" do
    before do
      contract.update!(start_date: 3.months.ago, fixed_monthly_price_cents: 1000)
      company.update!(promo_balance_cents: 2000, main_balance_cents: 0, lifecycle_status: :active)
    end

    it "creates a BillingInvoice" do
      expect { perform_job }.to change(BillingInvoice, :count).by(1)
    end

    it "auto-settles the invoice from wallet" do
      perform_job
      invoice = BillingInvoice.last
      expect(invoice.payment_status).to eq("paid")
      expect(company.reload.promo_balance_cents).to eq(1000)
    end
  end

  context "when company has empty wallet" do
    before do
      contract.update!(start_date: 3.months.ago, fixed_monthly_price_cents: 1000)
      company.update!(promo_balance_cents: 0, main_balance_cents: 0, lifecycle_status: :active)
    end

    it "creates invoice as unpaid" do
      perform_job
      expect(BillingInvoice.last.payment_status).to eq("unpaid")
    end

    it "does not deduct from wallet" do
      expect { perform_job }.not_to(change { company.reload.promo_balance_cents })
    end
  end

  context "when company has no active contract" do
    before do
      contract.update!(start_date: 3.months.ago)
      company.update!(lifecycle_status: :active)
      contract.update!(lifecycle_status: :expired)
    end

    it "does not create an invoice" do
      expect { perform_job }.not_to change(BillingInvoice, :count)
    end
  end

  context "when company has zero total charges" do
    before do
      contract.update!(start_date: 3.months.ago)
      company.update!(lifecycle_status: :active)
      contract.update!(fixed_monthly_price_cents: 0)
    end

    it "does not create an invoice for zero charges" do
      expect { perform_job }.not_to change(BillingInvoice, :count)
    end
  end

  context "when company has unpaid invoices with sufficient wallet" do
    before do
      contract.update!(start_date: 3.months.ago, fixed_monthly_price_cents: 1000)
      company.update!(promo_balance_cents: 2000, main_balance_cents: 0,
                      has_unpaid_invoices_at: 5.days.ago)
    end

    it "still creates a BillingInvoice" do
      expect { perform_job }.to change(BillingInvoice, :count).by(1)
    end

    it "auto-settles and keeps the company active" do
      perform_job
      invoice = BillingInvoice.last
      expect(invoice.payment_status).to eq("paid")
      expect(company.reload.lifecycle_status).to eq("active")
    end
  end

  context "when company is disabled" do
    before do
      company.update!(lifecycle_status: :disabled, promo_balance_cents: 0,
                      main_balance_cents: -5000, soft_debt_threshold_cents: -1000)
    end

    it "does not create an invoice" do
      expect { perform_job }.not_to change(BillingInvoice, :count)
    end
  end

  context "with multiple companies" do
    let(:company2) { create(:company, lifecycle_status: :active) }
    let!(:contract2) { company2.active_billing_contract }

    before do
      contract.update!(start_date: 3.months.ago, fixed_monthly_price_cents: 1000)
      contract2.update!(start_date: 3.months.ago, fixed_monthly_price_cents: 500)
      company.update!(promo_balance_cents: 2000, main_balance_cents: 0, lifecycle_status: :active)
      company2.update!(promo_balance_cents: 1000, main_balance_cents: 0)
    end

    it "processes all non-disabled companies" do
      expect { perform_job }.to change(BillingInvoice, :count).by(2)
    end
  end
end
