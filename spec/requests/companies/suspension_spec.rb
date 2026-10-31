# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Suspended company access", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before do
    get sign_in_for_test_path(email: owner.email)
    company.update!(workflow_status: :suspend)
  end

  describe "web" do
    it "redirects HTML company pages to the top-up page" do
      get "/companies/#{company.id}/dashboards"

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_company_top_up_path(company))
    end

    it "returns a 403 errors payload for JSON company requests" do
      get "/companies/#{company.id}/dashboards.json"

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"]).to contain_exactly(
        Companies::SuspendedCompanyConcern::COMPANY_SUSPENDED_MESSAGE
      )
    end

    it "keeps top-up, billing, and usage accessible" do
      get "/companies/#{company.id}/top_ups/new"
      expect(response).to have_http_status(:ok)

      get "/companies/#{company.id}/billing"
      expect(response).to have_http_status(:ok)

      get "/companies/#{company.id}/usage"
      expect(response).to have_http_status(:ok)
    end

    it "keeps the recovery JSON endpoints accessible" do
      get "/companies/#{company.id}/top_ups/new.json"
      expect(response).to have_http_status(:ok)

      get "/companies/#{company.id}/billing.json"
      expect(response).to have_http_status(:ok)

      get "/companies/#{company.id}/usage.json"
      expect(response).to have_http_status(:ok)
    end

    it "blocks company settings show/edit" do
      get "/companies/#{company.id}"
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_company_top_up_path(company))

      get "/companies/#{company.id}.json"
      expect(response).to have_http_status(:forbidden)
    end

    it "restores access after credits are added" do
      company.company_wallet.add_credits!(amount: 10)

      get "/companies/#{company.id}/dashboards"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "mobile" do
    it "returns 403 for mobile company pages while still allowing mobile sign-in" do
      get "/mobile/companies/#{company.id}/home"

      expect(response).to have_http_status(:forbidden)

      # A signed-in user is redirected from the sign-in page; either way the
      # suspension guard must not block the sign-in route itself.
      get "/mobile/sign_in"
      expect(response).not_to have_http_status(:forbidden)
    end
  end
end
