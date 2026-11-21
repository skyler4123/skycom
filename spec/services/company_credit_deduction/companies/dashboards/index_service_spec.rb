# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyCreditDeduction::Companies::Dashboards::IndexService do
  let(:company) { create(:company, :without_signup_promo) }
  let(:wallet) { company.company_wallet }

  it "resolves the dashboard action cost from CREDIT_DEDUCTION_RATES" do
    expect(described_class.new(company: company).send(:cost))
      .to eq(CREDIT_DEDUCTION_RATES.dig("companies/dashboards#index", :cost))
  end

  it "uses the access_dashboard action type for usage logs" do
    expect(described_class.new(company: company).send(:action_type)).to eq("access_dashboard")
  end

  it "deducts the dashboard cost from the wallet" do
    wallet.add_to!(balance: :main, amount: 100)

    described_class.call(company: company)

    cost = CREDIT_DEDUCTION_RATES.dig("companies/dashboards#index", :cost)
    expect(wallet.reload.main_credit_balance).to eq(100 - cost)
    expect(company.credit_usage_delta).to eq(cost)
  end
end
