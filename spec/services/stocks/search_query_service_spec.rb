# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stocks::SearchQueryService do
  let(:warehouse_cache) { Hash.new { |h, k| h[k] = create(:warehouse, company: k) } }

  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "stocks" }
    let(:index_class) { Stock }
    let(:record) do
      ->(company:, category:, **attrs) {
        product = create(:product, company: company, name: "Product #{SecureRandom.hex(4)}")
        create(:stock, company: company, warehouse: warehouse_cache[company], product: product, category: category, **attrs)
      }
    end
  end
end
