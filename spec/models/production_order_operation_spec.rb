# spec/models/production_order_operation_spec.rb
require "rails_helper"

RSpec.describe ProductionOrderOperation, type: :model do
  describe "table" do
    it "uses production_order_operations" do
      expect(described_class.table_name).to eq("production_order_operations")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:production_order) }
    it { should belong_to(:production_operation) }
    it { should belong_to(:work_center).optional }
    it { should belong_to(:employee).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:logged_minutes).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
