# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::BranchesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "branches" }
    let(:index_class) { Branch }
    let(:json_key) { "branches" }
    let(:base_json_path) { "/companies/#{company.id}/branches.json" }
    let(:record) { ->(company:, category:, **attrs) { create(:branch, company: company, category: category, discarded_at: nil, **attrs) } }
  end
end
