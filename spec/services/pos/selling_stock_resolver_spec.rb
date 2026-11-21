# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pos::SellingStockResolver do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:product) { create(:product, company: company, branch: branch) }
  let(:older_main) do
    create(:warehouse, company: company, branch: branch, name: "Main",
      business_type: :main, created_at: 2.days.ago)
  end
  let(:newer_overflow) do
    create(:warehouse, company: company, branch: branch, name: "Overflow",
      business_type: :distribution, created_at: 1.day.ago)
  end

  def stock_for(warehouse, quantity)
    category = product.category
    Stock.create!(
      company: company, warehouse: warehouse, product: product,
      quantity: quantity, pending: 0, category: category,
      property_mapping: category.default_property_mapping
    ).tap { |stock| stock.send(:sync_available_counter) }
  end

  it "prefers the main warehouse even when it is older than another warehouse" do
    main_stock = stock_for(older_main, 10)
    stock_for(newer_overflow, 50)

    resolved = described_class.for_products(company: company, branch: branch, products: [ product ])

    expect(resolved[product.id].id).to eq(main_stock.id)
  end

  it "falls through to the next warehouse when the main pile is empty" do
    stock_for(older_main, 0)
    overflow_stock = stock_for(newer_overflow, 5)

    resolved = described_class.for_products(company: company, branch: branch, products: [ product ])

    expect(resolved[product.id].id).to eq(overflow_stock.id)
  end

  it "falls back to the first warehouse with zero stock when nothing is available" do
    main_stock = stock_for(older_main, 0)
    stock_for(newer_overflow, 0)

    resolved = described_class.for_products(company: company, branch: branch, products: [ product ])

    expect(resolved[product.id].id).to eq(main_stock.id)
  end

  it "returns nil when the product is not stocked in the branch" do
    other_branch = create(:branch, company: company)
    other_warehouse = create(:warehouse, company: company, branch: other_branch)
    stock_for(other_warehouse, 10)

    resolved = described_class.for_products(company: company, branch: branch, products: [ product ])

    expect(resolved[product.id]).to be_nil
  end
end
