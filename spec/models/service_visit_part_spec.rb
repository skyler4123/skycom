# spec/models/service_visit_part_spec.rb
require "rails_helper"

RSpec.describe ServiceVisitPart, type: :model do
  describe "table" do
    it "uses service_visit_parts" do
      expect(described_class.table_name).to eq("service_visit_parts")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:service_visit) }
    it { should belong_to(:product) }
    it { should belong_to(:stock).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { should validate_numericality_of(:price_cents).only_integer.is_greater_than_or_equal_to(0) }
  end
end
