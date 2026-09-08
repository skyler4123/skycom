# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::DepartmentsController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "departments" }
    let(:index_class) { Department }
    let(:json_key) { "departments" }
    let(:base_json_path) { "/companies/#{company.id}/departments.json" }
    let(:record) { ->(company:, category:, **attrs) { create(:department, company: company, category: category, **attrs) } }
  end
end
