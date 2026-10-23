# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ClientCacheController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  describe "GET /client_cache" do
    it "includes company settings so the sidebar can render from cache" do
      record = CompanySetting.create!(
        company: company, name: "Company Quick Links", business_type: :sidebar_groups,
        workflow_status: :active,
        sidebar_groups: [
          { "key" => "my-links", "name" => "My Links",
            "items" => [ { "key" => "pending", "name" => "Pending", "url" => "/orders?workflow_status=pending" } ] }
        ]
      )

      get "/client_cache", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      payload_company = body["companies"].find { |c| c["id"] == company.id }
      expect(payload_company["company_settings"]).not_to be_nil
      ids = payload_company["company_settings"].map { |s| s["id"] }
      expect(ids).to include(record.id)
      found = payload_company["company_settings"].find { |s| s["id"] == record.id }
      expect(found["metadata"]["sidebar_groups"].first["name"]).to eq("My Links")
    end

    it "exposes no personal sidebar payload" do
      get "/client_cache", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).not_to have_key("personal_settings")
      expect(body).not_to have_key("enums")
    end
  end
end
