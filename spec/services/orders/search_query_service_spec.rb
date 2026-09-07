# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orders::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "orders" }
    let(:index_class) { Order }
    let(:record) do
      ->(company:, category:, **attrs) { create(:order, company: company, category: category, customer: create(:customer, company: company), **attrs) }
    end
  end
end
