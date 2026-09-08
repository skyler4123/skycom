# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::EmployeesController search/filter", type: :request do
  let(:resource_name) { "employees" }
  let(:index_class) { Employee }
  let(:json_key) { "employees" }
  let(:base_json_path) { "/companies/#{company.id}/employees.json" }
  let(:record) { ->(company:, category:, **attrs) { create(:employee, company: company, category: category, **attrs) } }

  it_behaves_like "dynamic search index controller"

  # The controller's pre-search scope is `current_company.employees.kept` —
  # a discarded employee must never resurface via the Meilisearch id list.
  it_behaves_like "dynamic search index scope intersection" do
    let(:hidden_record) do
      create(:employee, company: company, category: category, name: "Crimson Gone", property_integer_1: 50).tap(&:discard!)
    end
  end
end
