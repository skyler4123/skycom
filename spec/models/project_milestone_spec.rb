# spec/models/project_milestone_spec.rb
require "rails_helper"

RSpec.describe ProjectMilestone, type: :model do
  describe "table" do
    it "uses project_milestones" do
      expect(described_class.table_name).to eq("project_milestones")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:project) }
    it { should belong_to(:invoice).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_numericality_of(:amount_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
