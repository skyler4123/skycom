# frozen_string_literal: true

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
                      lifecycle_status: :active, soft_debt_threshold_cents: -10000)
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

    it "marks company as past_due" do
      expect { settle }
        .to change { company.reload.lifecycle_status }.from("active").to("past_due")
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
