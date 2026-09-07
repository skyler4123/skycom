# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::BrandsController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "brands" }
    let(:index_class) { Brand }
    let(:json_key) { "brands" }
    let(:base_json_path) { "/companies/#{company.id}/brands.json" }
    let(:record) { ->(company:, category:, **attrs) { create(:brand, company: company, category: category, **attrs) } }
  end
end
