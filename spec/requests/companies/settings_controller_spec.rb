# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::SettingsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/settings" do
    it "returns the company-appointed settings as JSON" do
      get "/companies/#{company.id}/settings", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["settings"].size).to eq(1)
      setting = body["settings"].first
      expect(setting["code"]).to eq("SETTINGS-DEFAULT")
      expect(setting["metadata"]["sidebar_items"]).to include({ "key" => "products", "visible" => true })
    end
  end

  describe "PATCH /companies/:company_id/settings/:id" do
    let(:setting) { company.settings.first }

    it "updates sidebar_items with real booleans" do
      patch "/companies/#{company.id}/settings/#{setting.id}",
        params: { setting: { sidebar_items: [ { key: "products", visible: false } ] } },
        as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["setting"]["metadata"]["sidebar_items"]).to eq([ { "key" => "products", "visible" => false } ])
      expect(setting.reload.sidebar_items).to eq([ { "key" => "products", "visible" => false } ])
    end

    it "returns 404 for a setting in another company" do
      other_company = create(:company)
      other_setting = other_company.settings.first
      patch "/companies/#{company.id}/settings/#{other_setting.id}",
        params: { setting: { sidebar_items: [] } },
        as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
