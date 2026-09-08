# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "products" }
    let(:index_class) { Product }
    let(:record) { ->(company:, category:, **attrs) { create(:product, company: company, category: category, **attrs) } }
  end

  it "inherits the shared safety cap" do
    expect(described_class::MS_SEARCH_MAX_IDS).to eq(DynamicSearch::BaseQueryService::MS_SEARCH_MAX_IDS)
  end

  it "rejects the abstract base without a model" do
    expect { DynamicSearch::BaseQueryService.model }.to raise_error(NotImplementedError)
  end
end
