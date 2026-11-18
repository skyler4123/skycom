# spec/models/channel_sync_log_spec.rb
require "rails_helper"

RSpec.describe ChannelSyncLog, type: :model do
  describe "table" do
    it "uses channel_sync_logs" do
      expect(described_class.table_name).to eq("channel_sync_logs")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:channel_connection) }
  end

  describe "enums" do
    it { should define_enum_for(:direction).with_prefix(true).with_values(inbound: 0, outbound: 1) }
    it { should define_enum_for(:status).with_prefix(true).with_values(pending: 0, running: 1, completed: 2, failed: 3) }
  end
end
