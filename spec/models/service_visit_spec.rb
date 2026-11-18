# spec/models/service_visit_spec.rb
require "rails_helper"

RSpec.describe ServiceVisit, type: :model do
  describe "table" do
    it "uses service_visits" do
      expect(described_class.table_name).to eq("service_visits")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:project).optional }
    it { should belong_to(:facility).optional }
    it { should belong_to(:assigned_employee).class_name("Employee").optional }
    it { should have_many(:service_visit_parts).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:scheduled_at) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
