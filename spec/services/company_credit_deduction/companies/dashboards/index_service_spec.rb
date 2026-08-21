# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyCreditDeduction::Companies::Dashboards::IndexService do
  let(:company) { create(:company) }
  let(:wallet) { company.company_wallet }

  it "resolves the dashboard action cost from CREDIT_USAGE_RATES" do
    expect(described_class.new(company: company).send(:cost)).to eq(CREDIT_USAGE_RATES[:access_dashboard])
  end

  it "uses the access_dashboard action type for usage logs" do
    expect(described_class.new(company: company).send(:action_type)).to eq("access_dashboard")
  end

  it "deducts the dashboard cost from the wallet" do
    wallet.add_to!(balance: :main, amount: 100)

    described_class.call(company: company)

    expect(wallet.reload.main_credit_balance).to eq(100 - CREDIT_USAGE_RATES[:access_dashboard])
    expect(company.credit_usage_delta).to eq(CREDIT_USAGE_RATES[:access_dashboard])
  end
end
