# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouses::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "warehouses" }
    let(:index_class) { Warehouse }
    let(:record) { ->(company:, category:, **attrs) { create(:warehouse, company: company, category: category, **attrs) } }
  end
end
