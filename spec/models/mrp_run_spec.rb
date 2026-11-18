# spec/models/mrp_run_spec.rb
require "rails_helper"

RSpec.describe MrpRun, type: :model do
  describe "table" do
    it "uses mrp_runs" do
      expect(described_class.table_name).to eq("mrp_runs")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:run_on) }
    it { should validate_numericality_of(:horizon_days).only_integer.is_greater_than(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
