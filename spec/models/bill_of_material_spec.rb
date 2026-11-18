# spec/models/bill_of_material_spec.rb
require "rails_helper"

RSpec.describe BillOfMaterial, type: :model do
  describe "table" do
    it "uses bill_of_materials" do
      expect(described_class.table_name).to eq("bill_of_materials")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:product) }
    it { should have_many(:bom_lines).dependent(:destroy) }
    it { should have_many(:production_routings).dependent(:destroy) }
    it { should have_many(:production_orders).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:version) }
    it { should validate_length_of(:version).is_at_most(32) }
    it "declares version uniqueness scoped to company_id, product_id" do
      validator = described_class.validators_on(:version).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id product_id])
    end
    it { should validate_numericality_of(:output_quantity).only_integer.is_greater_than(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
