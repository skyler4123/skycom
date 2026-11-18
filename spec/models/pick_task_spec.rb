# spec/models/pick_task_spec.rb
require "rails_helper"

RSpec.describe PickTask, type: :model do
  describe "table" do
    it "uses pick_tasks" do
      expect(described_class.table_name).to eq("pick_tasks")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:pick_wave) }
    it { should belong_to(:order) }
    it { should belong_to(:stock) }
    it { should belong_to(:stock_lot).optional }
    it { should belong_to(:storage_location).optional }
    it { should belong_to(:assigned_employee).class_name("Employee").optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end

describe "#short_picked?" do
  it "detects a short pick" do
    expect(described_class.new(quantity: 5, picked_quantity: 4)).to be_short_picked
    expect(described_class.new(quantity: 5, picked_quantity: 5)).not_to be_short_picked
  end
end
end
