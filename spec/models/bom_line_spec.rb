# spec/models/bom_line_spec.rb
require "rails_helper"

RSpec.describe BomLine, type: :model do
  describe "table" do
    it "uses bom_lines" do
      expect(described_class.table_name).to eq("bom_lines")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:bill_of_material) }
    it { should belong_to(:component_product).class_name("Product") }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
    it { should validate_numericality_of(:scrap_bp).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than(0) }
    it "declares position uniqueness scoped to bill_of_material_id" do
      validator = described_class.validators_on(:position).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[bill_of_material_id])
    end
  end

describe "#required_quantity_for" do
  it "scales component quantity by the production run" do
    line = described_class.new(quantity: 2, scrap_bp: 0)

    expect(line.required_quantity_for(10)).to eq(20)
  end

  it "adds the scrap allowance on top" do
    line = described_class.new(quantity: 100, scrap_bp: 500)

    expect(line.required_quantity_for(1).to_d).to eq(105)
  end
end
end
