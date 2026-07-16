# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SettlementService do
  subject(:settle) { described_class.call(invoice) }

  let(:company) { create(:company) }
  let(:contract) { company.active_billing_contract }
  let(:invoice) do
    create(:billing_invoice, company: company, billing_contract: contract,
           price_cents: 1500, period_start: 1.month.ago.beginning_of_month,
           period_end: 1.month.ago.end_of_month)
  end
  let(:wallet) { company.billing_wallet }

  before do
    wallet.update_columns(promo_balance_cents: 0, main_balance_cents: 0)
    company.update_columns(lifecycle_status: 0) # active
    wallet.reload
  end

  context "when promo balance covers the full amount" do
    before do
      invoice # force creation (balances are 0 → no auto-settlement)
      wallet.update_columns(promo_balance_cents: 2000, main_balance_cents: 0)
      wallet.reload
    end

    it "deducts from promo balance" do
      expect { settle }
        .to change { wallet.reload.promo_balance_cents }.from(2000).to(500)
    end

    it "marks invoice as paid" do
      settle
      expect(invoice.reload.payment_status).to eq("paid")
    end

    it "creates a BillingTransaction" do
      expect { settle }.to change(BillingTransaction, :count).by(1)
    end
  end

  context "when promo covers partial and main covers the rest" do
    before do
      invoice # force creation (balances are 0 → no auto-settlement)
      wallet.update_columns(promo_balance_cents: 500, main_balance_cents: 2000)
      wallet.reload
    end

    it "drains promo first" do
      settle
      expect(wallet.reload.promo_balance_cents).to eq(0)
    end

    it "deducts remaining from main" do
      expect { settle }
        .to change { wallet.reload.main_balance_cents }.from(2000).to(1000)
    end

    it "marks invoice as paid" do
      settle
      expect(invoice.reload.payment_status).to eq("paid")
    end

    it "records two BillingTransactions" do
      expect { settle }.to change(BillingTransaction, :count).by(2)
    end
  end

  context "when neither balance covers the amount" do
    before do
      invoice # force creation (balances are 0 → no auto-settlement)
      wallet.update_columns(promo_balance_cents: 500, main_balance_cents: 500,
                              soft_debt_threshold_cents: -10000)
      company.update_columns(lifecycle_status: Company.lifecycle_statuses[:active])
      wallet.reload
    end

    it "drains both balances" do
      settle
      expect(wallet.reload.promo_balance_cents).to eq(0)
      expect(wallet.reload.main_balance_cents).to eq(0)
    end

    it "marks invoice as overdue" do
      settle
      expect(invoice.reload.payment_status).to eq("overdue")
    end

    it "flags company as unpaid" do
      expect { settle }
        .to change { wallet.reload.has_unpaid_invoices_at }.from(nil)
    end
  end

  describe ".settle_all" do
    before do
      wallet.update_columns(promo_balance_cents: 0, main_balance_cents: 0)
      company.update_columns(lifecycle_status: 0) # active
      wallet.reload
      @invoice1 = create(:billing_invoice, company: company, billing_contract: contract,
                         price_cents: 1000, period_start: 2.months.ago.beginning_of_month,
                         period_end: 2.months.ago.end_of_month)
      @invoice2 = create(:billing_invoice, company: company, billing_contract: contract,
                         price_cents: 2000, period_start: 1.month.ago.beginning_of_month,
                         period_end: 1.month.ago.end_of_month)
      wallet.update_columns(
        has_unpaid_invoices_at: Time.current,
        suspension_at: Time.current.end_of_month,
        main_balance_cents: 3500,
        promo_balance_cents: 0,
        soft_debt_threshold_cents: -10000
      )
      wallet.reload
    end

    it "returns paid_count and remaining_cents" do
      result = described_class.settle_all(company)
      expect(result).to eq({ paid_count: 2, remaining_cents: 0 })
    end

    it "settles all unpaid invoices oldest-first" do
      described_class.settle_all(company)
      expect(@invoice1.reload.payment_status).to eq("paid")
      expect(@invoice2.reload.payment_status).to eq("paid")
    end

    it "stops when wallet is exhausted" do
      wallet.update_columns(main_balance_cents: 1500)
      wallet.reload
      result = described_class.settle_all(company)
      expect(result[:paid_count]).to eq(1)
      expect(result[:remaining_cents]).to eq(2000)
      expect(@invoice1.reload.payment_status).to eq("paid")
      expect(@invoice2.reload.payment_status).to eq("overdue")
    end

    it "does not settle already-paid invoices" do
      @invoice1.update!(payment_status: :paid)
      result = described_class.settle_all(company)
      expect(result[:paid_count]).to eq(1)
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

    it "does not create BillingTransactions" do
      expect { settle }.not_to change(BillingTransaction, :count)
    end
  end
end
