# spec/models/product_spec.rb
require 'rails_helper'

RSpec.describe Product, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:brand).optional }
    it { should belong_to(:tax_code).optional }
    it { should have_many(:order_product_appointments).dependent(:destroy) }
    it { should have_many(:orders).through(:order_product_appointments) }
    it { should have_many(:product_product_group_appointments).dependent(:destroy) }
    it { should have_many(:product_groups).through(:product_product_group_appointments) }
    it { should have_many(:employee_product_appointments).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }

    it "rejects a tax code from another company" do
      other = create(:tax_code)
      product = build(:product, company: create(:company), tax_code: other)

      expect(product).not_to be_valid
      expect(product.errors[:tax_code]).to be_present
    end
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(physical: 0, digital: 1, service_based: 2) }
  end

  describe "computed columns" do
    it "declares quantity as a computed index column" do
      expect(Product.computed_columns).to include(
        "key" => "quantity", "name" => "Quantity", "type" => "integer"
      )
    end

    it "sums stock quantities across warehouses" do
      company = create(:company)
      product = create(:product, company: company)
      warehouse_a = create(:warehouse, company: company)
      warehouse_b = create(:warehouse, company: company)

      Stock.create!(company: company, warehouse: warehouse_a, product: product, quantity: 5, pending: 0)
      Stock.create!(company: company, warehouse: warehouse_b, product: product, quantity: 3, pending: 0)

      expect(product.reload.quantity).to eq(8)
    end

    it "preloads one quantity per record for an index page" do
      company = create(:company)
      product = create(:product, company: company)
      empty_product = create(:product, company: company)
      warehouse = create(:warehouse, company: company)
      Stock.create!(company: company, warehouse: warehouse, product: product, quantity: 6, pending: 0)

      Product.preload_computed_columns([ product, empty_product ])

      expect(product.quantity).to eq(6)
      expect(empty_product.quantity).to eq(0)
    end
  end

  it_behaves_like "property_mapping concern", Product
end
