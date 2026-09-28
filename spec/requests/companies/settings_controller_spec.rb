# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::SettingsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

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
end
