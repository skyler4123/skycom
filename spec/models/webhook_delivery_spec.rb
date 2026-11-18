# spec/models/webhook_delivery_spec.rb
require "rails_helper"

RSpec.describe WebhookDelivery, type: :model do
  describe "table" do
    it "uses webhook_deliveries" do
      expect(described_class.table_name).to eq("webhook_deliveries")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:webhook_endpoint) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(pending: 0, delivered: 1, failed: 2, exhausted: 3) }
  end
end
