# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::EventConfigLogsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let!(:config) { EventConfig.create!(company: company, category: category) }

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
      log = EventConfigLog.create!(company: company, event_config: config, category: category,
        action: :created, category_name: category.name)

      get "/companies/#{company.id}/event_config_logs.json"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      ids = body["event_config_logs"].map { |l| l["id"] }
      expect(ids).to include(log.id)
      expect(body).to have_key("filters")
    end

    it "does not leak other companies logs" do
      other = create(:company)
      EventConfigLog.create!(company: other, action: :created)

      get "/companies/#{company.id}/event_config_logs.json"
      ids = JSON.parse(response.body)["event_config_logs"].map { |l| l["id"] }
      expect(ids).not_to include(EventConfigLog.where(company: other).pluck(:id))
    end

    it "filters by config and action" do
      other_category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "products")
      other_config = EventConfig.create!(company: company, category: other_category)
      keep = EventConfigLog.create!(company: company, event_config: config, action: :created)
      drop = EventConfigLog.create!(company: company, event_config: other_config, action: :updated)

      get "/companies/#{company.id}/event_config_logs.json", params: { event_config_id: config.id, log_action: "created" }
      ids = JSON.parse(response.body)["event_config_logs"].map { |l| l["id"] }
      expect(ids).to include(keep.id)
      expect(ids).not_to include(drop.id)
    end
  end

  describe "GET #show" do
    it "returns the log snapshot" do
      log = EventConfigLog.create!(company: company, event_config: config, action: :created,
        create_stock_pending: true, employee_name: "Jane")

      get "/companies/#{company.id}/event_config_logs/#{log.id}.json"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["event_config_log"]
      expect(body["create_stock_pending"]).to eq(true)
      expect(body["employee"]["name"]).to eq("Jane")
    end
  end

  describe "audit writes from EventConfigsController" do
    it "writes a created log on POST create" do
      fresh_category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
      EventConfig.where(company: company).delete_all

      expect {
        post "/companies/#{company.id}/event_configs",
          params: { event_config: { category_id: fresh_category.id, create_stock_pending: true } }
      }.to change { EventConfigLog.where(company: company).count }.by(1)

      log = EventConfigLog.where(company: company).order(:created_at).last
      expect(log.action).to eq("created")
      expect(log.create_stock_pending).to eq(true)
      expect(log.category_id).to eq(fresh_category.id)
    end

    it "writes an updated log on PATCH update" do
      expect {
        patch "/companies/#{company.id}/event_configs/#{config.id}",
          params: { event_config: { strict_stock_hold: true } }
      }.to change { EventConfigLog.where(company: company).count }.by(1)

      log = EventConfigLog.where(company: company).order(:created_at).last
      expect(log.action).to eq("updated")
      expect(log.strict_stock_hold).to eq(true)
      expect(log.event_config_id).to eq(config.id)
    end

    it "keeps the log when the config is destroyed (nullify)" do
      log = EventConfigLog.create!(company: company, event_config: config, action: :created)
      config.destroy!
      expect(log.reload.event_config_id).to be_nil
    end
  end

  describe "read-only routes" do
    it "does not route POST/PUT/DELETE" do
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/event_config_logs", method: :post)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/event_config_logs/1", method: :patch)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/event_config_logs/1", method: :delete)
      }.to raise_error(ActionController::RoutingError)
    end
  end
end
