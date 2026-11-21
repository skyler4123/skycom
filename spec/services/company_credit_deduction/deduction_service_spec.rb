# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyCreditDeduction::DeductionService do
  let(:company) { create(:company, :without_signup_promo) }
  let(:wallet) { company.company_wallet }

  def deduct(**overrides)
    described_class.call(
      company: company,
      amount: 10,
      action_type: "access_dashboard",
      description: "Dashboard access",
      **overrides
    )
  end

  it "charges the explicit amount with promo-first priority" do
    wallet.add_to!(balance: :promo, amount: 6)
    wallet.add_to!(balance: :main, amount: 100)

    expect(deduct).to be(true)

    expect(wallet.reload.promo_credit_balance).to eq(0)
    expect(wallet.main_credit_balance).to eq(96)
    expect(company.credit_usage_delta).to eq(10)
  end

  it "writes the provided description and source to the wallet log" do
    wallet.add_to!(balance: :main, amount: 100)
    source = create(:customer, company: company, name: "Charge Source")

    deduct(source: source, description: "Custom charge")

    log = CompanyWalletLog.where(change_type: :debit).last
    expect(log.description).to eq("Custom charge")
    expect(log.source).to eq(source)
  end

  it "skips a suspended company by default" do
    wallet.add_to!(balance: :main, amount: 100)
    company.reload.sync_credit_status!(total_credit_balance: 0)
    expect(company.suspended?).to be(true)

    expect { deduct }.not_to change(CompanyWalletLog, :count)
    expect(wallet.reload.main_credit_balance).to eq(100)
    expect(company.credit_usage_delta).to eq(0)
  end

  it "charges a suspended company when allow_suspended is true" do
    wallet.add_to!(balance: :main, amount: 100)
    company.reload.sync_credit_status!(total_credit_balance: 0)

    expect(deduct(allow_suspended: true)).to be(true)

    expect(wallet.reload.main_credit_balance).to eq(90)
    expect(company.credit_usage_delta).to eq(10)
  end

  it "rejects an action type that is not in the credit catalog" do
    wallet.add_to!(balance: :main, amount: 100)

    expect { deduct(action_type: "unknown_action") }.to raise_error(ArgumentError, /unknown credit action_type/)
  end

  it "does not charge a zero or negative amount" do
    wallet.add_to!(balance: :main, amount: 100)

    expect { deduct(amount: 0) }.not_to change(CompanyWalletLog, :count)
    expect { deduct(amount: -5) }.not_to change(CompanyWalletLog, :count)
  end

  it "does not charge when the company has no wallet" do
    wallet.destroy!
    company.reload

    expect { deduct }.not_to change(CompanyWalletLog, :count)
  end

  it "deduplicates a retried call with the same external_id" do
    wallet.add_to!(balance: :main, amount: 100)

    expect(deduct(external_id: "job-123")).to be(true)
    expect(deduct(external_id: "job-123")).to be(false)

    expect(wallet.reload.main_credit_balance).to eq(90)
    expect(company.credit_usage_delta).to eq(10)
  end
end
