# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::SuppliersController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "suppliers" }
    let(:index_class) { Supplier }
    let(:json_key) { "suppliers" }
    let(:base_json_path) { "/companies/#{company.id}/suppliers.json" }
    let(:record) { ->(company:, category:, **attrs) { create(:supplier, company: company, category: category, **attrs) } }
  end
end
