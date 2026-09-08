# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::FacilitiesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "facilities" }
    let(:index_class) { Facility }
    let(:json_key) { "facilities" }
    let(:base_json_path) { "/companies/#{company.id}/facilities.json" }
    let(:record) { ->(company:, category:, **attrs) { create(:facility, company: company, category: category, **attrs) } }
  end
end
