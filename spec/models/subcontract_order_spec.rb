# spec/models/subcontract_order_spec.rb
require "rails_helper"

RSpec.describe SubcontractOrder, type: :model do
  describe "table" do
    it "uses subcontract_orders" do
      expect(described_class.table_name).to eq("subcontract_orders")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:supplier) }
    it { should belong_to(:purchase).optional }
    it { should belong_to(:product) }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, sent: 1, partially_received: 2, received: 3, cancelled: 4) }
  end
end
