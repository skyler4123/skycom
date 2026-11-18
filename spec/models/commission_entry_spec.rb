# spec/models/commission_entry_spec.rb
require "rails_helper"

RSpec.describe CommissionEntry, type: :model do
  describe "table" do
    it "uses commission_entries" do
      expect(described_class.table_name).to eq("commission_entries")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:commission_plan) }
    it { should belong_to(:order).optional }
    it { should belong_to(:invoice).optional }
    it { should belong_to(:payroll).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:base_cents).only_integer }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(pending: 0, approved: 1, paid: 2, cancelled: 3) }
  end
end
