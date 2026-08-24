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
    let(:company) { create(:company) }
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
      expect(wallet.lock_version).to eq(1)
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

    it "raises InsufficientCreditsError and leaves the balance unchanged" do
      wallet.add_credits!(amount: 10)

      expect {
        wallet.deduct_from!(balance: :main, amount: 20)
      }.to raise_error(CompanyWallet::InsufficientCreditsError)

      expect(wallet.reload.main_credit_balance).to eq(10)
      expect(CompanyWalletLog.count).to eq(1)
    end

    it "keeps each balance independent" do
      wallet.add_to!(balance: :promo, amount: 50)
      wallet.add_to!(balance: :debt, amount: 5)

      expect(wallet.main_credit_balance).to eq(0)
      expect(wallet.promo_credit_balance).to eq(50)
      expect(wallet.debt_credit_balance).to eq(5)

      wallet.deduct_from!(balance: :promo, amount: 10)
      expect(wallet.promo_credit_balance).to eq(40)
      expect(wallet.main_credit_balance).to eq(0)

      expect(CompanyWalletLog.pluck(:balance_type)).to eq(%w[promo debt promo])
    end

    it "rejects non-positive amounts" do
      expect { wallet.add_to!(balance: :main, amount: 0) }.to raise_error(ArgumentError)
      expect { wallet.deduct_from!(balance: :main, amount: -5) }.to raise_error(ArgumentError)
    end

    it "rejects unknown balance keys" do
      expect { wallet.add_to!(balance: :savings, amount: 10) }.to raise_error(ArgumentError)
      expect { wallet.deduct_from!(balance: :savings, amount: 10) }.to raise_error(ArgumentError)
    end

    it "raises StaleObjectError when a stale object is saved" do
      wallet.add_credits!(amount: 100)
      stale = CompanyWallet.find(wallet.id)
      wallet.add_credits!(amount: 50)

      expect { stale.update!(main_credit_balance: 999) }.to raise_error(ActiveRecord::StaleObjectError)
    end
  end

  describe "usage logging toggle" do
    let(:company) { create(:company) }
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
