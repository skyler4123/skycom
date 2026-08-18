# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::CreditDataService do
  describe ".create" do
    let(:company) { create(:company, country: :us) }
    let(:today) { Time.current.to_date }

    before do
      create(:billing_payment_method, :mock_qr, code: "QR_BANK_TRANSFER")
    end

    it "credits the wallet through the purchase chain" do
      expect {
        described_class.create(company: company)
      }.to change(CompanyOrder, :count).by(2)
        .and change(CompanyInvoice, :count).by(2)
        .and change(CompanyTransaction, :count).by(2)
        .and change(CompanyWalletLog, :count).by(2)

      expect(company.company_orders.map(&:workflow_status)).to all(eq("completed"))
      expect(company.company_invoices.map(&:payment_status)).to all(eq("paid"))

      expected_balance = CREDIT_RATES[:us].first(2).to_h.values.sum
      expect(company.company_wallet.reload.credit_balance).to eq(expected_balance)
    end

    it "seeds 7 days of daily usage with consistent totals" do
      described_class.create(company: company)

      usages = CompanyDailyUsage.where(company: company).order(:usage_date)
      expect(usages.count).to eq(7)
      expect(usages.map(&:usage_date)).to eq((6.days.ago.to_date..today).to_a)

      usages.each do |usage|
        hours_sum = (0..23).sum { |h| usage.hour_usage(h) }
        expect(usage.total_credits).to eq(hours_sum)
      end
    end

    it "seeds monthly usage for the current and previous month" do
      described_class.create(company: company)

      months = CompanyMonthlyUsage.where(company: company)
      expect(months.count).to eq(2)
      expect(months.map(&:usage_month)).to contain_exactly(today.beginning_of_month, today.prev_month.beginning_of_month)

      months.each do |usage|
        days_sum = (1..31).sum { |d| usage.day_usage(d) }
        expect(usage.total_credits).to eq(days_sum)
      end
    end

    it "leaves a live unsynced delta in the Kredis counter" do
      described_class.create(company: company)

      expect(company.credit_usage_delta).to be > 0
    end
  end
end
