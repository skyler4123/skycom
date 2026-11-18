# spec/models/product_barcode_spec.rb
require "rails_helper"

RSpec.describe ProductBarcode, type: :model do
  describe "table" do
    it "uses product_barcodes" do
      expect(described_class.table_name).to eq("product_barcodes")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:product) }
  end

  describe "validations" do
    it { should validate_presence_of(:barcode) }
    it { should validate_length_of(:barcode).is_at_most(128) }
    it "declares barcode uniqueness scoped to company_id" do
      validator = described_class.validators_on(:barcode).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_numericality_of(:pack_quantity).only_integer.is_greater_than(0) }
  end
end
