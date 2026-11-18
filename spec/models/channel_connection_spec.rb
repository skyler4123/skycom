# spec/models/channel_connection_spec.rb
require "rails_helper"

RSpec.describe ChannelConnection, type: :model do
  describe "table" do
    it "uses channel_connections" do
      expect(described_class.table_name).to eq("channel_connections")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:channel_sync_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:channel).with_prefix(true).with_values(shopify: 0, woocommerce: 1, amazon: 2, shopee: 3, lazada: 4, tiktok: 5) }
  end
end
