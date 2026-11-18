# spec/models/notification_delivery_spec.rb
require "rails_helper"

RSpec.describe NotificationDelivery, type: :model do
  describe "table" do
    it "uses notification_deliveries" do
      expect(described_class.table_name).to eq("notification_deliveries")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:notification) }
    it { should belong_to(:notification_channel) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(pending: 0, sent: 1, failed: 2, bounced: 3) }
  end
end
