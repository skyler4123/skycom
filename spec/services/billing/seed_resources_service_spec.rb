# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SeedResourcesService do
  describe ".call" do
    it "creates volumetric billing resources for all countries" do
      expect { described_class.call }.to change(BillingResource.volumetric, :count).by(14)
    end

    it "creates addon feature billing resources for all countries" do
      expect { described_class.call }.to change(BillingResource.addon_feature, :count).by(32)
    end

    it "is idempotent" do
      described_class.call
      expect { described_class.call }.not_to change(BillingResource, :count)
    end

    it "creates an orders resource for US" do
      described_class.call
      expect(BillingResource.find_by(name: "orders", country: :us)).to be_present
    end

    it "creates an orders resource for VN" do
      described_class.call
      expect(BillingResource.find_by(name: "orders", country: :vn)).to be_present
    end

    it "creates an analytics_dashboard resource for US" do
      described_class.call
      expect(BillingResource.find_by(name: "analytics_dashboard", country: :us)).to be_present
    end

    it "creates an analytics_dashboard resource for VN" do
      described_class.call
      expect(BillingResource.find_by(name: "analytics_dashboard", country: :vn)).to be_present
    end
  end
end
