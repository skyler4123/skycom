# spec/models/notification_channel_spec.rb
require "rails_helper"

RSpec.describe NotificationChannel, type: :model do
  describe "table" do
    it "uses notification_channels" do
      expect(described_class.table_name).to eq("notification_channels")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:notification_deliveries).dependent(:destroy) }
  end

  describe "validations" do
    it "declares channel uniqueness scoped to company_id" do
      validator = described_class.validators_on(:channel).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:channel).with_prefix(true).with_values(email: 0, slack: 1, teams: 2, zalo: 3, whatsapp: 4, push: 5, sms: 6) }
  end
end
