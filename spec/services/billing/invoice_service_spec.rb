# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::InvoiceService do
  subject(:invoice) { described_class.call(company, calculator_result) }

  let(:company) { create(:company) }
  let(:period_start) { 1.month.ago.beginning_of_month }
  let(:period_end) { 1.month.ago.end_of_month }

  let!(:contract) do
    create(:billing_contract, company: company, lifecycle_status: :active, start_date: 3.months.ago)
  end

  let(:calculator_result) do
    Billing::CalculatorService::Result.new(
      total_cents: 1500,
      breakdown: Billing::CalculatorService::Breakdown.new(
        base_cents: 1000, features_cents: 500, overages: {}
      )
    )
  end

  it "creates a BillingInvoice" do
    expect { invoice }.to change(BillingInvoice, :count).by(1)
  end

  it "sets the correct total" do
    expect(invoice.price_cents).to eq(1500)
  end

  it "links to the active contract" do
    expect(invoice.billing_contract).to eq(contract)
  end

  it "sets the period" do
    expect(invoice.period_start.to_i).to eq(period_start.to_i)
    expect(invoice.period_end.to_i).to eq(period_end.to_i)
  end

  it "starts as unpaid" do
    expect(invoice.payment_status).to eq("unpaid")
  end

  it "is finalized" do
    expect(invoice.lifecycle_status).to eq("final")
  end

  context "when no active contract exists" do
    before { contract.update!(lifecycle_status: :expired) }

    it "returns nil" do
      expect(invoice).to be_nil
    end
  end
end
