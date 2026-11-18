# spec/models/maintenance_plan_spec.rb
require "rails_helper"

RSpec.describe MaintenancePlan, type: :model do
  describe "table" do
    it "uses maintenance_plans" do
      expect(described_class.table_name).to eq("maintenance_plans")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:facility).optional }
    it { should belong_to(:fixed_asset).optional }
    it { should have_many(:maintenance_checks).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

describe "trigger" do
  it "requires a day interval or a usage interval" do
    plan = described_class.new(name: "Quarterly service")
    plan.valid?

    expect(plan.errors[:base]).to include("requires an interval in days or in usage units")
  end

  it "accepts a day interval" do
    plan = described_class.new(name: "Quarterly service", interval_days: 90)
    plan.valid?

    expect(plan.errors[:base]).to eq([])
  end
end
end
