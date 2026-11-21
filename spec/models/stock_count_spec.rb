# frozen_string_literal: true

require "rails_helper"

RSpec.describe StockCount, type: :model do
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

  def build_count(status: :draft, **attributes)
    StockCount.create!(
      company: company, warehouse: warehouse, count_type: :cycle,
      status: status, started_at: Time.current, **attributes
    )
  end

  it "exposes the status enum and the open scope" do
    draft = build_count(status: :draft)
    completed = build_count(status: :completed, completed_at: Time.current)

    expect(StockCount.open_counts).to include(draft)
    expect(StockCount.open_counts).not_to include(completed)
    expect(StockCount.completed_recent_first).to include(completed)
  end

  describe "table" do
    it "uses stock_counts" do
      expect(described_class.table_name).to eq("stock_counts")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:warehouse) }
    it { should belong_to(:created_by_employee).class_name("Employee").optional }
    it { should have_many(:stock_count_lines).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:count_type).with_prefix(true).with_values(full: 0, cycle: 1, spot: 2, blind: 3) }
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, in_progress: 1, completed: 2, cancelled: 3) }
  end

  it "allows one open count per warehouse" do
    build_count(status: :in_progress)

    duplicate = StockCount.new(company: company, warehouse: warehouse, count_type: :cycle, status: :in_progress)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:base]).to include("A count is already in progress for this warehouse")
  end

  it "allows a new count after the previous one is completed" do
    previous = build_count(status: :in_progress)
    previous.update!(status: :completed, completed_at: Time.current)

    expect(build_count(status: :in_progress)).to be_persisted
  end

  it "sums line variance and reports counted rows" do
    count = build_count(status: :in_progress)
    count.stock_count_lines.create!(stock: stock, expected_quantity: 10, counted_quantity: 8, variance_quantity: -2)

    expect(count.variance_quantity).to eq(-2)
    expect(count.rows_counted).to eq(1)
    expect(count.rows_total).to eq(1)
  end
end
