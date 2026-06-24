# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SeedResourcesService do
  describe ".call" do
    it "creates volumetric billing resources" do
      expect { described_class.call }.to change(BillingResource.volumetric, :count).by(7)
    end

    it "creates addon feature billing resources" do
      expect { described_class.call }.to change(BillingResource.addon_feature, :count).by(12)
    end

    it "is idempotent" do
      described_class.call
      expect { described_class.call }.not_to change(BillingResource, :count)
    end

    it "creates an orders resource" do
      described_class.call
      expect(BillingResource.find_by(name: "orders")).to be_present
    end

    it "creates an analytics_dashboard resource" do
      described_class.call
      expect(BillingResource.find_by(name: "analytics_dashboard")).to be_present
    end
  end
end
