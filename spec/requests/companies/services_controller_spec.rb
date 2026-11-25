# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::ServicesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "services" }
    let(:index_class) { Service }
    let(:json_key) { "services" }
    let(:base_json_path) { "/companies/#{company.id}/services.json" }
    # Direct create: the :service factory's nested `association :branch, company: company`
    # rejects a company: override (FactoryBot treats it as an association attribute).
    let(:record) { ->(company:, category:, **attrs) { Service.create!(company: company, category: category, business_type: :b2c, **attrs) } }
  end
end

RSpec.describe "Companies::ServicesController tax", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "services") }
  let(:service) do
    Service.create!(
      company: company, category: category, business_type: :b2c,
      name: "Taxable service", property_mapping: category.default_property_mapping
    )
  end

  before { get sign_in_for_test_path(email: company.user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  it "returns the effective tax code and assigns one" do
    code = create(:tax_code, company: company, name: "VAT", rate_bp: 1_000)

    get "/companies/#{company.id}/services/#{service.id}.json"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["effective_tax_code"]).to be_nil

    patch "/companies/#{company.id}/services/#{service.id}.json",
      params: { service: { tax_code_id: code.id } }

    expect(response).to have_http_status(:ok), response.body
    expect(service.reload.tax_code).to eq(code)
  end

  it "rejects another company's tax code" do
    patch "/companies/#{company.id}/services/#{service.id}.json",
      params: { service: { tax_code_id: create(:tax_code).id } }

    expect(response).to have_http_status(:unprocessable_content), response.body
    expect(service.reload.tax_code).to be_nil
  end
end
