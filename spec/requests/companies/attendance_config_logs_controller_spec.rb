# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::AttendanceConfigLogsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:branch) { company.branches.first || create(:branch, company: company) }
  let!(:config) do
    AttendanceConfig.where(branch: branch).destroy_all
    AttendanceConfig.create!(company: company, branch: branch,
      latitude: 10.773, longitude: 106.694,
      allowed_radius_meters: 100, resolution_strategy: :paired)
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
      log = AttendanceConfigLog.create!(company: company, attendance_config: config,
        branch: branch, action: :created, branch_name: branch.name)

      get "/companies/#{company.id}/attendance_config_logs.json"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      ids = body["attendance_config_logs"].map { |l| l["id"] }
      expect(ids).to include(log.id)
      expect(body).to have_key("filters")
    end

    it "filters by branch and action" do
      keep = AttendanceConfigLog.create!(company: company, attendance_config: config,
        branch: branch, action: :created)
      drop = AttendanceConfigLog.create!(company: company, action: :updated)

      get "/companies/#{company.id}/attendance_config_logs.json",
        params: { branch_id: branch.id, log_action: "created" }
      ids = JSON.parse(response.body)["attendance_config_logs"].map { |l| l["id"] }
      expect(ids).to include(keep.id)
      expect(ids).not_to include(drop.id)
    end
  end

  describe "GET #show" do
    it "returns the log snapshot" do
      log = AttendanceConfigLog.create!(company: company, attendance_config: config,
        action: :created, allowed_radius_meters: 250, employee_name: "Jane")

      get "/companies/#{company.id}/attendance_config_logs/#{log.id}.json"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["attendance_config_log"]
      expect(body["allowed_radius_meters"]).to eq(250)
      expect(body["employee"]["name"]).to eq("Jane")
    end
  end

  describe "audit writes from AttendanceConfigsController" do
    it "writes a created log on POST create" do
      branch2 = create(:branch, company: company)

      expect {
        post "/companies/#{company.id}/attendance_configs",
          params: { attendance_config: { branch_id: branch2.id, latitude: 11.1,
            longitude: 106.8, allowed_radius_meters: 200, resolution_strategy: "paired" } }
      }.to change { AttendanceConfigLog.where(company: company).count }.by(1)

      log = AttendanceConfigLog.where(company: company).order(:created_at).last
      expect(log.action).to eq("created")
      expect(log.allowed_radius_meters).to eq(200)
      expect(log.branch_id).to eq(branch2.id)
    end

    it "writes an updated log on PATCH update" do
      expect {
        patch "/companies/#{company.id}/attendance_configs/#{config.id}",
          params: { attendance_config: { allowed_radius_meters: 500 } }
      }.to change { AttendanceConfigLog.where(company: company).count }.by(1)

      log = AttendanceConfigLog.where(company: company).order(:created_at).last
      expect(log.action).to eq("updated")
      expect(log.allowed_radius_meters).to eq(500)
      expect(log.attendance_config_id).to eq(config.id)
    end

    it "keeps the log when the config is destroyed (nullify)" do
      log = AttendanceConfigLog.create!(company: company, attendance_config: config, action: :created)
      config.destroy!
      expect(log.reload.attendance_config_id).to be_nil
    end
  end

  describe "read-only routes" do
    it "does not route POST/PUT/DELETE" do
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/attendance_config_logs", method: :post)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/attendance_config_logs/1", method: :patch)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/attendance_config_logs/1", method: :delete)
      }.to raise_error(ActionController::RoutingError)
    end
  end
end
