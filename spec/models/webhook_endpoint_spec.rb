# spec/models/webhook_endpoint_spec.rb
require "rails_helper"

RSpec.describe WebhookEndpoint, type: :model do
  describe "table" do
    it "uses webhook_endpoints" do
      expect(described_class.table_name).to eq("webhook_endpoints")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:webhook_deliveries).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:url) }
    it { should validate_length_of(:url).is_at_most(2048) }
  end

describe "#subscribed_to?" do
  it "matches only subscribed event keys" do
    endpoint = described_class.new(url: "https://example.test/hook", event_keys: [ "invoice.paid" ])

    expect(endpoint.subscribed_to?("invoice.paid")).to be(true)
    expect(endpoint.subscribed_to?("stock.low")).to be(false)
  end
end
end
