# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContractFeature, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:billing_resource) }
    it { is_expected.to belong_to(:billing_contract) }
  end

  describe "validations" do
    subject do
      build(:contract_feature,
            billing_resource: create(:billing_resource, :addon_feature, name: "test_feat"),
            billing_contract: create(:billing_contract))
    end

    it { is_expected.to validate_uniqueness_of(:billing_resource_id).scoped_to(:billing_contract_id).with_message("is already assigned to this contract").ignoring_case_sensitivity }
    it { is_expected.to validate_presence_of(:monthly_flat_price_cents) }
    it { is_expected.to validate_numericality_of(:monthly_flat_price_cents).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:lifecycle_status).with_values(active: 0, disabled: 1) }
  end

  describe "#must_be_addon_feature_type validation" do
    let(:contract) { create(:billing_contract) }

    it "allows addon_feature resources" do
      addon = create(:billing_resource, :addon_feature, name: "valid_addon")
      feature = build(:contract_feature, billing_resource: addon, billing_contract: contract)
      expect(feature).to be_valid
    end

    it "rejects volumetric resources" do
      vol = create(:billing_resource, :volumetric, name: "invalid_vol")
      feature = build(:contract_feature, billing_resource: vol, billing_contract: contract)
      expect(feature).not_to be_valid
      expect(feature.errors[:billing_resource]).to include("must be an addon_feature type to fit into contract_features")
    end
  end
end
