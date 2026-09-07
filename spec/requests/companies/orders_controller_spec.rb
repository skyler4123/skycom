# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::OrdersController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "orders" }
    let(:index_class) { Order }
    let(:json_key) { "orders" }
    let(:base_json_path) { "/companies/#{company.id}/orders.json" }
    let(:record) do
      ->(company:, category:, **attrs) { create(:order, company: company, category: category, customer: create(:customer, company: company), **attrs) }
    end
  end
end
