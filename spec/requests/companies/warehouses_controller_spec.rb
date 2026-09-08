# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::WarehousesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "warehouses" }
    let(:index_class) { Warehouse }
    let(:json_key) { "warehouses" }
    let(:base_json_path) { "/companies/#{company.id}/warehouses.json" }
    let(:record) { ->(company:, category:, **attrs) { create(:warehouse, company: company, category: category, **attrs) } }
  end
end

RSpec.describe "Companies::WarehousesController CRUD", type: :request do
  let(:company) { create(:company) }
  let(:other) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "warehouses") }
  let(:warehouse) { create(:warehouse, company: company, category: category, name: "Central Depot") }

  before { get sign_in_for_test_path(email: company.user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  it "creates a warehouse and redirects to the show page" do
    expect {
      post "/companies/#{company.id}/warehouses",
        params: { warehouse: { name: "New Depot", category_id: category.id, business_type: "main" } }
    }.to change(Warehouse, :count).by(1)

    created = Warehouse.find_by(name: "New Depot")
    expect(created.branch).to be_nil
    expect(response).to redirect_to("/companies/#{company.id}/warehouses/#{created.id}")
    follow_redirect!
    expect(response.body).to include("created successfully")
  end

  it "updates a warehouse and redirects to the show page" do
    patch "/companies/#{company.id}/warehouses/#{warehouse.id}",
      params: { warehouse: { name: "Renamed Depot" } }

    expect(warehouse.reload.name).to eq("Renamed Depot")
    expect(response).to redirect_to("/companies/#{company.id}/warehouses/#{warehouse.id}")
  end

  it "excludes warehouses of other companies from index JSON" do
    foreign = create(:warehouse, company: other)

    get "/companies/#{company.id}/warehouses.json"

    expect(response).to have_http_status(:ok)
    ids = JSON.parse(response.body)["warehouses"].map { |w| w["id"] }
    expect(ids).not_to include(foreign.id)
  end

  it "returns 404 when showing another company's warehouse" do
    foreign = create(:warehouse, company: other)

    get "/companies/#{company.id}/warehouses/#{foreign.id}.json"

    expect(response).to have_http_status(:not_found)
  end

  it "serves the HTML shells for index/show/new/edit" do
    warehouse

    get "/companies/#{company.id}/warehouses"
    expect(response).to have_http_status(:ok)
    get "/companies/#{company.id}/warehouses/#{warehouse.id}"
    expect(response).to have_http_status(:ok)
    get "/companies/#{company.id}/warehouses/new"
    expect(response).to have_http_status(:ok)
    get "/companies/#{company.id}/warehouses/#{warehouse.id}/edit"
    expect(response).to have_http_status(:ok)
  end

  it "emits dynamic property columns in the show JSON" do
    warehouse.update!(property_string_1: "Region North")

    get "/companies/#{company.id}/warehouses/#{warehouse.id}.json"

    body = JSON.parse(response.body)["warehouse"]
    expect(body["property_string_1"]).to eq("Region North")
    expect(body["category"]["id"]).to eq(category.id)
  end
end
