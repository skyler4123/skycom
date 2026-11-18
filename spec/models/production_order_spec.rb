# spec/models/production_order_spec.rb
require "rails_helper"

RSpec.describe ProductionOrder, type: :model do
  describe "table" do
    it "uses production_orders" do
      expect(described_class.table_name).to eq("production_orders")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:product) }
    it { should belong_to(:bill_of_material).optional }
    it { should belong_to(:warehouse) }
    it { should have_many(:production_order_materials).dependent(:destroy) }
    it { should have_many(:production_order_operations).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
