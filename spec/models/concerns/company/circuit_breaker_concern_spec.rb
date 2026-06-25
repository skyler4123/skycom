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
