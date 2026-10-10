# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ClientCacheController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  describe "GET /client_cache" do
    it "includes company-level settings so the dynamic sidebar can render from cache" do
      setting = Setting.create!(
        company: company, appoint_to: company, code: DYNAMIC_SIDEBAR_CODE,
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :company,
        sidebar_groups: [
          { "key" => "my-links", "name" => "My Links",
            "items" => [ { "key" => "pending", "name" => "Pending", "url" => "/orders?workflow_status=pending" } ] }
        ]
      )

      get "/client_cache", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      payload_company = body["companies"].find { |c| c["id"] == company.id }
      expect(payload_company["settings"]).not_to be_nil
      ids = payload_company["settings"].map { |s| s["id"] }
      expect(ids).to include(setting.id)
      record = payload_company["settings"].find { |s| s["id"] == setting.id }
      expect(record["metadata"]["sidebar_groups"].first["name"]).to eq("My Links")
    end
  end
end
