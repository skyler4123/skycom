# frozen_string_literal: true

require "rails_helper"

RSpec.describe Deduct::BaseService do
  let(:company) { create(:company) }
  let(:wallet) { company.company_wallet }

  # Concrete subclass — the epic base is exercised through a real implementation.
  let(:service_class) do
    Class.new(described_class) do
      def action_type = "access_dashboard"
      def description = "Dashboard access"
    end
  end

  describe ".call" do
    it "deducts from the promo balance first when it covers the cost" do
      wallet.add_to!(balance: :promo, amount: 50)
      wallet.add_to!(balance: :main, amount: 100)

      expect { service_class.call(company: company) }.to change(wallet, :promo_credit_balance).by(-2)

      expect(wallet.reload.promo_credit_balance).to eq(48)
      expect(wallet.main_credit_balance).to eq(100)
      expect(wallet.debt_credit_balance).to eq(0)
    end

    it "deducts the remainder from main when promo cannot cover the cost" do
      wallet.add_to!(balance: :promo, amount: 1)
      wallet.add_to!(balance: :main, amount: 100)

      service_class.call(company: company)

      expect(wallet.reload.promo_credit_balance).to eq(0)
      expect(wallet.main_credit_balance).to eq(99)
      expect(wallet.debt_credit_balance).to eq(0)
    end

    it "deducts fully from main when promo is empty" do
      wallet.add_to!(balance: :main, amount: 100)

      service_class.call(company: company)

      expect(wallet.reload.promo_credit_balance).to eq(0)
      expect(wallet.main_credit_balance).to eq(98)
      expect(wallet.debt_credit_balance).to eq(0)
    end

    it "absorbs the uncovered remainder into debt when promo and main are exhausted" do
      wallet.add_to!(balance: :main, amount: 1)

      service_class.call(company: company)

      expect(wallet.reload.main_credit_balance).to eq(0)
      expect(wallet.debt_credit_balance).to eq(1)
    end

    it "records credit usage via the Kredis counter" do
      wallet.add_to!(balance: :main, amount: 100)

      service_class.call(company: company)

      expect(company.credit_usage_delta).to eq(2)
    end

    it "is a no-op when the cost is zero" do
      free_service = Class.new(described_class) do
        def action_type = "not_in_rates"
      end

      expect { free_service.call(company: company) }
        .not_to change(CompanyWalletLog, :count)
      expect(company.credit_usage_delta).to eq(0)
    end

    it "is a no-op when the company has no wallet" do
      wallet.destroy!
      company.reload

      expect { service_class.call(company: company) }
        .not_to change(CompanyWalletLog, :count)
    end

    it "lets subclasses control whether the deduction runs" do
      wallet.add_to!(balance: :main, amount: 100)
      guarded_service = Class.new(described_class) do
        def action_type = "access_dashboard"
        def should_run? = false
      end

      guarded_service.call(company: company)

      expect(wallet.reload.main_credit_balance).to eq(100)
      expect(company.credit_usage_delta).to eq(0)
    end

    it "writes one audit log row per balance touched" do
      wallet.add_to!(balance: :promo, amount: 1)
      wallet.add_to!(balance: :main, amount: 5)

      expect { service_class.call(company: company) }
        .to change(CompanyWalletLog, :count).by(2)

      expect(CompanyWalletLog.order(:created_at, :id).last(2).pluck(:balance_type)).to eq(%w[promo main])
    end
  end
end
