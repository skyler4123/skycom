# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Credit deduction rates" do
  it "prices the dashboard index page at 2 credits" do
    expect(CREDIT_DEDUCTION_RATES.fetch("companies/dashboards#index")).to include(
      cost: 2,
      action_type: "access_dashboard",
      charge_on: :first_json
    )
  end

  it "prices the analytics index page at 2 credits" do
    expect(CREDIT_DEDUCTION_RATES.fetch("companies/analytics#index")).to include(
      cost: 2,
      action_type: "access_analytics",
      charge_on: :first_json
    )
  end

  it "prices every operation show page at 3 credits" do
    OPERATION_TYPES.each_key do |operation_type|
      key = "companies/operations/#{operation_type}#show"

      expect(CREDIT_DEDUCTION_RATES.fetch(key)).to include(
        cost: 3,
        charge_on: :first_json
      )
    end
  end

  it "charges page loads on the first JSON request, never the HTML shell" do
    expect(CREDIT_DEDUCTION_RATES.values.map { |rule| rule[:charge_on] }.uniq).to eq([ :first_json ])
  end

  it "registers every page action type in the usage-log catalog" do
    action_types = CREDIT_DEDUCTION_RATES.values.map { |rule| rule[:action_type] }

    expect(CREDIT_DEDUCTION_ACTION_TYPES).to include(*action_types)
    expect(CREDIT_DEDUCTION_ACTION_TYPES).to include("top_up", "deduction")
  end

  it "grants one million promo credits to every new company" do
    expect(SIGNUP_PROMO_CREDITS).to eq(1_000_000)
  end
end
