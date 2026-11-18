# spec/models/product_bundle_spec.rb
require "rails_helper"

RSpec.describe ProductBundle, type: :model do
  describe "table" do
    it "uses product_bundles" do
      expect(described_class.table_name).to eq("product_bundles")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:product) }
    it { should have_many(:product_bundle_components).dependent(:destroy) }
  end

  describe "validations" do
    it "declares product_id uniqueness scoped to company_id" do
      validator = described_class.validators_on(:product_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end
end
