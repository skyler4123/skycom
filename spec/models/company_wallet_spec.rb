# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyWallet, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:walletable) }
    it { should have_many(:company_wallet_logs).dependent(:destroy) }
    it { should have_many(:company_usage_logs).dependent(:destroy) }
  end

  describe "balance mutations" do
    let(:company) { create(:company, :without_signup_promo) }
    let(:wallet) { company.company_wallet }

    it "adds credits to the main balance and records an audit log with before/after snapshots" do
      expect {
        wallet.add_credits!(amount: 500_000, source: nil, description: "Top-up")
      }.to change(wallet, :main_credit_balance).by(500_000)
        .and change(CompanyWalletLog, :count).by(1)

      log = CompanyWalletLog.last
      expect(log.change_type).to eq("credit")
      expect(log.change_amount).to eq(500_000)
      expect(log.balance_before).to eq(0)
      expect(log.balance_after).to eq(500_000)
      expect(log.balance_type).to eq("main")
    end

    it "deducts from a single balance when the balance is sufficient" do
      wallet.add_credits!(amount: 100)

      expect {
        wallet.deduct_from!(balance: :main, amount: 30, source: nil, description: "Order creation")
      }.to change(wallet, :main_credit_balance).by(-30)
        .and change(CompanyWalletLog, :count).by(1)

      log = CompanyWalletLog.last
      expect(log.change_type).to eq("debit")
      expect(log.change_amount).to eq(-30)
      expect(log.balance_before).to eq(100)
      expect(log.balance_after).to eq(70)
      expect(log.balance_type).to eq("main")
    end

    it "allows the balance to go negative" do
      wallet.add_credits!(amount: 10)

      expect {
        wallet.deduct_from!(balance: :main, amount: 20)
      }.to change(wallet, :main_credit_balance).by(-20)

      expect(wallet.reload.main_credit_balance).to eq(-10)
      expect(company.reload.workflow_status).to eq("suspend")
      expect(CompanyWalletLog.count).to eq(2)
      expect(CompanyWalletLog.last.balance_after).to eq(-10)
    end

    it "keeps each balance independent" do
      wallet.add_to!(balance: :promo, amount: 50)

      expect(wallet.main_credit_balance).to eq(0)
      expect(wallet.promo_credit_balance).to eq(50)

      wallet.deduct_from!(balance: :promo, amount: 10)
      expect(wallet.promo_credit_balance).to eq(40)
      expect(wallet.main_credit_balance).to eq(0)

      expect(CompanyWalletLog.pluck(:balance_type)).to eq(%w[promo promo])
    end

    it "rejects non-positive amounts" do
      expect { wallet.add_to!(balance: :main, amount: 0) }.to raise_error(ArgumentError)
      expect { wallet.deduct_from!(balance: :main, amount: -5) }.to raise_error(ArgumentError)
    end

    it "rejects unknown balance keys" do
      expect { wallet.add_to!(balance: :savings, amount: 10) }.to raise_error(ArgumentError)
      expect { wallet.deduct_from!(balance: :savings, amount: 10) }.to raise_error(ArgumentError)
    end
  end

  describe "company credit status" do
    let(:company) { create(:company, :without_signup_promo) }
    let(:wallet) { company.company_wallet }

    it "suspends the company when a deduction reaches zero" do
      wallet.add_credits!(amount: 10)

      wallet.deduct_from!(balance: :main, amount: 10)

      expect(company.reload.workflow_status).to eq("suspend")
    end

    it "keeps the company active while the total balance is positive" do
      wallet.add_credits!(amount: 10)

      wallet.deduct_from!(balance: :main, amount: 4)

      expect(company.reload.workflow_status).to eq("active")
    end

    it "reactivates a suspended company when credits are added" do
      company.update!(workflow_status: :suspend)

      wallet.add_credits!(amount: 10)

      expect(company.reload.workflow_status).to eq("active")
    end
  end

  describe "usage logging toggle" do
    let(:company) { create(:company, :without_signup_promo) }
    let(:wallet) { company.company_wallet }

    it "is inactive by default" do
      expect(wallet.usage_logging_active?).to be false
    end

    it "becomes active within the window and expires after it" do
      travel_to(Time.zone.local(2026, 8, 18, 10, 0, 0)) do
        wallet.enable_usage_logging!(window: 5.minutes)
        expect(wallet.usage_logging_active?).to be true

        travel(6.minutes)
        expect(wallet.usage_logging_active?).to be false
      end
    end

    it "can be disabled immediately" do
      wallet.enable_usage_logging!
      wallet.disable_usage_logging!
      expect(wallet.usage_logging_active?).to be false
    end

    it "writes a CompanyUsageLog only while logging is active" do
      expect {
        wallet.add_credits!(amount: 100)
      }.not_to change(CompanyUsageLog, :count)

      wallet.enable_usage_logging!(window: 5.minutes)
      expect {
        wallet.deduct_from!(balance: :main, amount: 10, source: nil, description: "Order", action_type: "create_order")
      }.to change(CompanyUsageLog, :count).by(1)

      log = CompanyUsageLog.last
      expect(log.action_type).to eq("create_order")
      expect(log.change_amount).to eq(-10)
      expect(log.balance_after).to eq(90)
    end

    it "logs wallet movements that rely on default action types while active" do
      wallet.enable_usage_logging!(window: 5.minutes)

      expect {
        wallet.add_credits!(amount: 50)
        wallet.deduct_from!(balance: :main, amount: 10)
        wallet.add_to!(balance: :promo, amount: 5)
      }.to change(CompanyUsageLog, :count).by(3)

      expect(CompanyUsageLog.pluck(:action_type)).to contain_exactly("top_up", "deduction", "top_up")
    end
  end
end
