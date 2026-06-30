# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContractMetric, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:billing_resource) }
    it { is_expected.to belong_to(:billing_contract) }
  end

  describe "validations" do
    subject do
      build(:contract_metric,
            billing_resource: create(:billing_resource, :volumetric, name: "test_met"),
            billing_contract: create(:billing_contract))
    end

    it { is_expected.to validate_uniqueness_of(:billing_resource_id).scoped_to(:billing_contract_id).with_message("is already metered on this contract").ignoring_case_sensitivity }
    it { is_expected.to validate_presence_of(:free_allowance) }
    it { is_expected.to validate_numericality_of(:free_allowance).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:unit_price_cents) }
    it { is_expected.to validate_numericality_of(:unit_price_cents).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:lifecycle_status).with_values(active: 0, disabled: 1) }
  end

  describe "#must_be_volumetric_type validation" do
    let(:contract) { create(:billing_contract) }

    it "allows volumetric resources" do
      vol = create(:billing_resource, :volumetric, name: "valid_vol2")
      metric = build(:contract_metric, billing_resource: vol, billing_contract: contract)
      expect(metric).to be_valid
    end

    it "rejects addon_feature resources" do
      addon = create(:billing_resource, :addon_feature, name: "invalid_addon2")
      metric = build(:contract_metric, billing_resource: addon, billing_contract: contract)
      expect(metric).not_to be_valid
      expect(metric.errors[:billing_resource]).to include("must be a volumetric type to fit into contract_metrics")
    end
  end
end
