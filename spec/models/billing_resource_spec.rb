# frozen_string_literal: true

require "rails_helper"

RSpec.describe BillingResource, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:contract_features).dependent(:destroy) }
    it { is_expected.to have_many(:contract_metrics).dependent(:destroy) }
    it { is_expected.to have_many(:daily_metric_logs).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:billing_resource, name: "unique_test_resource") }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:country) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:resource_type).with_values(volumetric: 0, addon_feature: 1) }
    it { is_expected.to define_enum_for(:lifecycle_status).with_values(active: 0, deprecated: 1, archived: 2) }
  end

  describe ".volumetric scope" do
    let!(:vol) { create(:billing_resource, :volumetric, name: "test_vol") }
    let!(:addon) { create(:billing_resource, :addon_feature, name: "test_addon") }

    it "returns only volumetric resources" do
      expect(BillingResource.volumetric).to include(vol)
      expect(BillingResource.volumetric).not_to include(addon)
    end
  end

  describe ".addon_feature scope" do
    let!(:vol) { create(:billing_resource, :volumetric, name: "test_vol2") }
    let!(:addon) { create(:billing_resource, :addon_feature, name: "test_addon2") }

    it "returns only addon_feature resources" do
      expect(BillingResource.addon_feature).to include(addon)
      expect(BillingResource.addon_feature).not_to include(vol)
    end
  end
end
