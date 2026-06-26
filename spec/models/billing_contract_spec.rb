# frozen_string_literal: true

require "rails_helper"

RSpec.describe BillingContract, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to have_many(:contract_features).dependent(:destroy) }
    it { is_expected.to have_many(:contract_metrics).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:contract_type) }
    it { is_expected.to validate_presence_of(:start_date) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:contract_type).with_values(free_tier: 0, pay_as_you_go: 1, enterprise: 2) }
    it { is_expected.to define_enum_for(:lifecycle_status).with_values(draft: 0, active: 1, expired: 2, terminated: 3) }
  end

  describe ".currently_active scope" do
    let(:company) { create(:company) }
    let!(:active_contract) do
      create(:billing_contract, company: company, lifecycle_status: :active, start_date: 3.months.ago)
    end
    let!(:expired_contract) do
      create(:billing_contract, company: company, lifecycle_status: :expired, start_date: 6.months.ago)
    end

    it "returns active contracts" do
      expect(BillingContract.currently_active).to include(active_contract)
    end

    it "excludes expired contracts" do
      expect(BillingContract.currently_active).not_to include(expired_contract)
    end
  end

  describe "#attach_resource_metric!" do
    let(:company) { create(:company) }
    let(:contract) { company.active_billing_contract }
    let(:resource) { create(:billing_resource, :volumetric, name: "test_metric_resource") }

    it "creates a ContractMetric with the given allowance and pricing" do
      expect {
        contract.attach_resource_metric!(resource, allowance: 500, pricing: 25)
      }.to change(ContractMetric, :count).by(1)

      metric = ContractMetric.last
      expect(metric.free_allowance).to eq(500)
      expect(metric.unit_price_cents).to eq(25)
    end
  end
end
