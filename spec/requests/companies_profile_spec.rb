require "rails_helper"

RSpec.describe "CompaniesController#show/edit/update (Owner-only Company pages)", type: :request do
  let(:company) { create(:company) }
  let(:owner_email) { company.user.email }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:id (show)" do
    it "returns the company JSON for the owner" do
      get sign_in_for_test_path(email: owner_email)
      get company_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["company"]["id"]).to eq(company.id)
    end

    it "forbids non-owner employees with errors key" do
      plain = create(:employee, company: company)
      get sign_in_for_test_path(email: plain.user.email)
      get company_path(company), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "forbids cross-company access" do
      other = create(:company)
      get sign_in_for_test_path(email: other.user.email)
      get company_path(company), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "GET /companies/:id/edit" do
    it "returns the company JSON for the owner" do
      get sign_in_for_test_path(email: owner_email)
      get edit_company_path(company), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["company"]["id"]).to eq(company.id)
    end

    it "forbids non-owner employees with errors key" do
      plain = create(:employee, company: company)
      get sign_in_for_test_path(email: plain.user.email)
      get edit_company_path(company), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "PATCH /companies/:id (update)" do
    it "updates the company name for the owner" do
      get sign_in_for_test_path(email: owner_email)
      patch company_path(company), params: { company: { name: "Renamed Co" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["company"]["name"]).to eq("Renamed Co")
      expect(company.reload.name).to eq("Renamed Co")
    end

    it "rejects invalid params with errors key and no side-effect" do
      get sign_in_for_test_path(email: owner_email)
      patch company_path(company), params: { company: { name: "" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "forbids non-owner employees with errors key" do
      plain = create(:employee, company: company)
      get sign_in_for_test_path(email: plain.user.email)
      patch company_path(company), params: { company: { name: "Hacked" } }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to have_key("errors")
      expect(company.reload.name).not_to eq("Hacked")
    end
  end
end
