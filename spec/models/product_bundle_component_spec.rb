# spec/models/product_bundle_component_spec.rb
require "rails_helper"

RSpec.describe ProductBundleComponent, type: :model do
  describe "table" do
    it "uses product_bundle_components" do
      expect(described_class.table_name).to eq("product_bundle_components")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:product_bundle) }
    it { should belong_to(:component_product).class_name("Product") }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it "declares component_product_id uniqueness scoped to product_bundle_id" do
      validator = described_class.validators_on(:component_product_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[product_bundle_id])
    end
  end

describe "component" do
  it "refuses to make a bundle its own component" do
    product_id = SecureRandom.uuid
    bundle = ProductBundle.new(product_id: product_id)
    component = described_class.new(product_bundle: bundle, component_product_id: product_id)
    component.valid?

    expect(component.errors[:component_product]).to include("cannot be the bundle itself")
  end
end
end
