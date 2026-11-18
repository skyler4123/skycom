# spec/models/invoice_reminder_spec.rb
require "rails_helper"

RSpec.describe InvoiceReminder, type: :model do
  describe "table" do
    it "uses invoice_reminders" do
      expect(described_class.table_name).to eq("invoice_reminders")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:invoice) }
  end

  describe "validations" do
    it { should validate_numericality_of(:level).only_integer.is_greater_than(0) }
  end

  describe "enums" do
    it { should define_enum_for(:channel).with_prefix(true).with_values(email: 0, sms: 1, in_app: 2, letter: 3) }
    it { should define_enum_for(:status).with_prefix(true).with_values(scheduled: 0, sent: 1, failed: 2, skipped: 3) }
  end
end
