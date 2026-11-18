# spec/models/production_routing_spec.rb
require "rails_helper"

RSpec.describe ProductionRouting, type: :model do
  describe "table" do
    it "uses production_routings" do
      expect(described_class.table_name).to eq("production_routings")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:bill_of_material) }
    it { should have_many(:production_operations).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:version) }
    it { should validate_length_of(:version).is_at_most(32) }
    it "declares version uniqueness scoped to company_id, bill_of_material_id" do
      validator = described_class.validators_on(:version).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id bill_of_material_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
