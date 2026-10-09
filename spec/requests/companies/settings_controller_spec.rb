# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::SettingsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  describe "GET /companies/:company_id/settings" do
    it "returns an empty settings list when the company has no settings" do
      get "/companies/#{company.id}/settings", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["settings"]).to eq([])
    end

    it "returns company-level settings when they exist" do
      setting = Setting.create!(
        company: company, appoint_to: company, code: "FUTURE",
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :system
      )

      get "/companies/#{company.id}/settings", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["settings"].map { |s| s["id"] }).to eq([ setting.id ])
    end
  end

  describe "PATCH /companies/:company_id/settings/:id" do
    let!(:setting) do
      Setting.create!(
        company: company, appoint_to: company, code: DYNAMIC_SIDEBAR_CODE,
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :company,
        sidebar_groups: []
      )
    end

    it "updates sidebar_groups as the owner" do
      groups = [
        { "key" => "my-links", "name" => "My Links",
          "items" => [ { "key" => "pending", "name" => "Pending Orders", "url" => "/orders?workflow_status=pending" } ] }
      ]
      patch "/companies/#{company.id}/settings/#{setting.id}",
        params: { setting: { metadata: { sidebar_groups: groups } } }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["setting"]["metadata"]["sidebar_groups"]).to eq(groups)
      expect(setting.reload.sidebar_groups).to eq(groups)
    end

    it "returns 422 with errors for invalid sidebar_groups" do
      patch "/companies/#{company.id}/settings/#{setting.id}",
        params: { setting: { metadata: { sidebar_groups: [ { "key" => "g1" } ] } } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns 404 for a setting from another company" do
      other_company = create(:company)
      foreign = Setting.create!(
        company: other_company, appoint_to: other_company, code: DYNAMIC_SIDEBAR_CODE,
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :company,
        sidebar_groups: []
      )

      patch "/companies/#{company.id}/settings/#{foreign.id}",
        params: { setting: { metadata: { sidebar_groups: [] } } }, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns 403 for an employee without update permission" do
      employee = create(:employee, company: company)
      company.clear_permissions_cache
      get sign_in_for_test_path(email: employee.user.email)

      patch "/companies/#{company.id}/settings/#{setting.id}",
        params: { setting: { metadata: { sidebar_groups: [] } } }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
