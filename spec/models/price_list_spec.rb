# spec/models/price_list_spec.rb
require "rails_helper"

RSpec.describe PriceList, type: :model do
  describe "table" do
    it "uses price_lists" do
      expect(described_class.table_name).to eq("price_lists")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer_group).optional }
    it { should have_many(:price_list_items).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it "declares name uniqueness scoped to company_id" do
      validator = described_class.validators_on(:name).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end
end
