# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::TableConfigLogsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let!(:config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "products",
      metadata: { "columns" => [ { "key" => "name", "name" => "Name", "visible" => true } ] })
  end

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "returns logs scoped to the company with actor info" do
      log = TableConfigLog.create!(company: company, table_config: config,
        category: category, action: :created, name: "Grid")

      get "/companies/#{company.id}/table_config_logs.json"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      ids = body["table_config_logs"].map { |l| l["id"] }
      expect(ids).to include(log.id)
      expect(body).to have_key("filters")
    end

    it "filters by config and action" do
      keep = TableConfigLog.create!(company: company, table_config: config, action: :created)
      drop = TableConfigLog.create!(company: company, action: :updated)

      get "/companies/#{company.id}/table_config_logs.json",
        params: { table_config_id: config.id, log_action: "created" }
      ids = JSON.parse(response.body)["table_config_logs"].map { |l| l["id"] }
      expect(ids).to include(keep.id)
      expect(ids).not_to include(drop.id)
    end
  end

  describe "GET #show" do
    it "returns the log snapshot with columns" do
      log = TableConfigLog.create!(company: company, table_config: config,
        action: :created, name: "Grid", employee_name: "Jane",
        metadata: { "columns" => [ { "key" => "name", "name" => "Name", "visible" => true } ] })

      get "/companies/#{company.id}/table_config_logs/#{log.id}.json"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["table_config_log"]
      expect(body["metadata"]["columns"].first["key"]).to eq("name")
      expect(body["employee"]["name"]).to eq("Jane")
    end
  end

  describe "audit writes from TableConfigsController" do
    it "writes a created log on POST create" do
      TableConfig.where(company: company).delete_all

      expect {
        post "/companies/#{company.id}/table_configs",
          params: { table_config: { category_id: category.id,
            property_mapping_id: category.default_property_mapping.id,
            name: "Cashier", description: "till view" } }
      }.to change { TableConfigLog.where(company: company).count }.by(1)

      log = TableConfigLog.where(company: company).order(:created_at).last
      expect(log.action).to eq("created")
      expect(log.name).to eq("Cashier")
    end

    it "writes an updated log on PATCH update" do
      expect {
        patch "/companies/#{company.id}/table_configs/#{config.id}",
          params: { table_config: { name: "Renamed" } }
      }.to change { TableConfigLog.where(company: company).count }.by(1)

      log = TableConfigLog.where(company: company).order(:created_at).last
      expect(log.action).to eq("updated")
      expect(log.name).to eq("Renamed")
      expect(log.table_config_id).to eq(config.id)
    end

    it "keeps the log when the config is destroyed (nullify)" do
      log = TableConfigLog.create!(company: company, table_config: config, action: :created)
      config.destroy!
      expect(log.reload.table_config_id).to be_nil
    end
  end

  describe "read-only routes" do
    it "does not route POST/PUT/DELETE" do
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/table_config_logs", method: :post)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/table_config_logs/1", method: :patch)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/table_config_logs/1", method: :delete)
      }.to raise_error(ActionController::RoutingError)
    end
  end
end
