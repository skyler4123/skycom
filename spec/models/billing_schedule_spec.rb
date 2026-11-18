# spec/models/billing_schedule_spec.rb
require "rails_helper"

RSpec.describe BillingSchedule, type: :model do
  describe "table" do
    it "uses billing_schedules" do
      expect(described_class.table_name).to eq("billing_schedules")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:subscription_group) }
    it { should have_many(:invoices).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_numericality_of(:interval_count).only_integer.is_greater_than(0) }
    it { should validate_presence_of(:next_run_on) }
  end

  describe "enums" do
    it { should define_enum_for(:interval).with_prefix(true).with_values(weekly: 0, monthly: 1, quarterly: 2, yearly: 3) }
  end
end
