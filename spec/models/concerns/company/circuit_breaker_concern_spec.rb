# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company::CircuitBreakerConcern do
  subject(:company) { create(:company, lifecycle_status: :active) }

  before do
    company.billing_wallet.update!(soft_debt_threshold_cents: -1000,
                                    main_balance_cents: 0, promo_balance_cents: 0)
  end

  describe "#flag_unpaid!" do
    it "sets has_unpaid_invoices_at and suspension_at" do
      expect { company.flag_unpaid! }
        .to change { company.reload.billing_wallet.has_unpaid_invoices_at }.from(nil)
    end

    it "sets suspension_at to end of current month" do
      company.flag_unpaid!
      expect(company.reload.billing_wallet.suspension_at).to be_within(1.day).of(Time.current.end_of_month)
    end

    it "is idempotent when already flagged" do
      company.flag_unpaid!
      expect { company.flag_unpaid! }.not_to raise_error
    end
  end

  describe "#is_accessible?" do
    it "returns false when lifecycle_status is suspended" do
      company.update!(lifecycle_status: :suspended)
      expect(company.is_accessible?).to be false
    end

    it "returns true when lifecycle_status is active" do
      expect(company.is_accessible?).to be true
    end

    it "returns true when lifecycle_status is active even with suspension_at in future" do
      company.billing_wallet.update!(suspension_at: 1.day.from_now)
      expect(company.is_accessible?).to be true
    end
  end

  describe "#try_reactivate!" do
    it "transitions from suspended to active when no unpaid invoices exist" do
      company.update!(lifecycle_status: :suspended)
      company.billing_wallet.update!(suspension_at: Time.current.end_of_month)
      company.try_reactivate!
      expect(company.reload.lifecycle_status).to eq("active")
    end

    it "clears suspension_at on reactivation" do
      company.update!(lifecycle_status: :suspended)
      company.billing_wallet.update!(suspension_at: Time.current.end_of_month)
      company.try_reactivate!
      expect(company.reload.billing_wallet.suspension_at).to be_nil
    end

    it "stays suspended when unpaid invoices exist" do
      company.update!(lifecycle_status: :suspended)
      create(:billing_invoice, company: company, payment_status: :unpaid, price_cents: 1000)
      company.try_reactivate!
      expect(company.reload.lifecycle_status).to eq("suspended")
    end

    it "transitions when all invoices are paid" do
      company.update!(lifecycle_status: :suspended)
      create(:billing_invoice, company: company, payment_status: :paid, price_cents: 1000)
      company.try_reactivate!
      expect(company.reload.lifecycle_status).to eq("active")
    end
  end

  describe "auto_settle_unpaid_invoices on balance change" do
    it "fires for active companies with unpaid invoices" do
      create(:billing_invoice, company: company, payment_status: :unpaid, price_cents: 1000)
      expect(Billing::SettlementService).to receive(:settle_all).with(company).and_call_original
      company.billing_wallet.update!(main_balance_cents: 5000)
    end

    it "fires for companies with unpaid invoices flagged as unpaid" do
      create(:billing_invoice, company: company, payment_status: :unpaid, price_cents: 1000)
      company.billing_wallet.update!(has_unpaid_invoices_at: Time.current, suspension_at: Time.current.end_of_month)
      expect(Billing::SettlementService).to receive(:settle_all).with(company).and_call_original
      company.billing_wallet.update!(main_balance_cents: 5000)
    end

    it "does not fire for disabled companies" do
      company.update!(lifecycle_status: :disabled)
      create(:billing_invoice, company: company, payment_status: :unpaid, price_cents: 1000)
      expect(Billing::SettlementService).not_to receive(:settle_all)
      company.billing_wallet.update!(main_balance_cents: 5000)
    end
  end

  describe "#disabled is terminal" do
    before do
      company.update!(lifecycle_status: :disabled)
      company.billing_wallet.update_columns(main_balance_cents: 0, promo_balance_cents: 0)
    end

    it "does not allow flag_unpaid! on disabled company" do
      expect { company.flag_unpaid! }
        .to raise_error(ActiveRecord::RecordInvalid, /disabled/)
    end
  end
end
