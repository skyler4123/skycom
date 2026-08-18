# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyOrder, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:user) }
    it { should have_one(:company_invoice).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:currency).with_values(usd: 840, vnd: 704).with_prefix(:currency) }
  end

  describe "rate tier validation" do
    it "accepts a valid US tier" do
      order = build(:company_order, company: create(:company, country: :us), money_amount_cents: 500, credit_amount: 500_000)
      expect(order).to be_valid
    end

    it "accepts a valid VN tier" do
      order = build(:company_order, company: create(:company, country: :vn), money_amount_cents: 10_000_000, credit_amount: 400_000)
      expect(order).to be_valid
    end

    it "rejects a money amount that is not a rate tier for the company country" do
      order = build(:company_order, company: create(:company, country: :us), money_amount_cents: 123, credit_amount: 500_000)
      expect(order).not_to be_valid
      expect(order.errors[:money_amount_cents]).to include("is not an available credit rate tier")
    end

    it "rejects a credit amount that does not match the tier" do
      order = build(:company_order, company: create(:company, country: :us), money_amount_cents: 500, credit_amount: 999)
      expect(order).not_to be_valid
      expect(order.errors[:credit_amount]).to include("does not match the rate tier (500000 credits expected)")
    end
  end

  describe "#credits_per_cent" do
    it "computes credits per cent from the stored pair" do
      order = create(:company_order, money_amount_cents: 500, credit_amount: 500_000)
      expect(order.credits_per_cent).to eq(1000)
    end
  end

  describe "#complete!" do
    it "credits the company wallet exactly once and marks the order completed" do
      company = create(:company, country: :us)
      order = create(:company_order, company: company, money_amount_cents: 500, credit_amount: 500_000)
      wallet = company.wallet

      expect {
        order.complete!
      }.to change(wallet, :credit_balance).by(500_000)
        .and change(CompanyWalletLog, :count).by(1)
      expect(order.reload.workflow_status).to eq("completed")
      expect(wallet.reload.walletable).to eq(order)

      expect {
        order.complete!
      }.not_to change(wallet, :credit_balance)
      expect(CompanyWalletLog.count).to eq(1)
    end

    it "does nothing when the order is already completed" do
      company = create(:company, country: :us)
      order = create(:company_order, company: company, money_amount_cents: 500, credit_amount: 500_000, workflow_status: :completed)

      expect { order.complete! }.not_to change(CompanyWalletLog, :count)
      expect(company.wallet.credit_balance).to eq(0)
    end
  end
end
