# frozen_string_literal: true

require "rails_helper"

RSpec.describe StockCountLine, type: :model do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:product) { create(:product, company: company, business_type: :physical) }
  let(:stock) do
    Seed::StockService.create(
      company: company, warehouse: warehouse, branch: branch,
      product_id: product.id, name: product.name, code: product.code,
      quantity: 10, pending: 0, discarded_at: nil
    ).tap { |record| record.update!(discarded_at: nil) }
  end
  let(:count) do
    StockCount.create!(
      company: company, warehouse: warehouse, count_type: :cycle, status: :in_progress, started_at: Time.current
    )
  end

  it "records a counted value and its variance" do
    line = count.stock_count_lines.create!(stock: stock, expected_quantity: 10)

    line.record_count!(7)

    expect(line.counted_quantity).to eq(7)
    expect(line.variance_quantity).to eq(-3)
    expect(line).to be_counted
  end

  describe "table" do
    it "uses stock_count_lines" do
      expect(described_class.table_name).to eq("stock_count_lines")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:stock_count) }
    it { should belong_to(:stock) }
    it { should belong_to(:storage_location).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:expected_quantity).only_integer }

    it "declares stock_id uniqueness scoped to stock_count_id" do
      validator = described_class.validators_on(:stock_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[stock_count_id])
    end
  end

  it "clears the variance when the counted value is cleared" do
    line = count.stock_count_lines.create!(stock: stock, expected_quantity: 10, counted_quantity: 7, variance_quantity: -3)

    line.record_count!(nil)

    expect(line.counted_quantity).to be_nil
    expect(line.variance_quantity).to eq(0)
    expect(line).not_to be_counted
  end

  it "rejects a negative counted quantity" do
    line = count.stock_count_lines.new(stock: stock, expected_quantity: 10, counted_quantity: -1)

    expect(line).not_to be_valid
    expect(line.errors[:counted_quantity]).to be_present
  end
end
