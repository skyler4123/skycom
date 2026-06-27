require "rails_helper"

RSpec.describe "Admin::Companies", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:company_owner_user) { create(:user, :company_owner) }
  let!(:company1) { create(:company) }
  let!(:company2) { create(:company) }

  let(:json_headers) { { "ACCEPT" => "application/json" } }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /admin/companies" do
    context "when signed in as admin" do
      before do
        get sign_in_for_test_path(email: admin.email)
      end

      it "returns 200 with JSON array of companies" do
        get "/admin/companies", headers: json_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["companies"]).to be_an(Array)
        expect(body["companies"].length).to eq(2)
        expect(body["companies"].map { |c| c["name"] }).to include(company1.name, company2.name)
      end

      it "includes pagination data" do
        get "/admin/companies", headers: json_headers

        body = JSON.parse(response.body)
        expect(body["pagination"]).to be_present
      end

      it "includes user data for each company" do
        get "/admin/companies", headers: json_headers

        body = JSON.parse(response.body)
        company = body["companies"].find { |c| c["id"] == company1.id }
        expect(company["user"]).to be_present
        expect(company["user"]["name"]).to eq(company1.user.name)
      end
    end

    context "when signed in as non-admin" do
      before do
        get sign_in_for_test_path(email: company_owner_user.email)
      end

      it "redirects to root" do
        get "/admin/companies"

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get "/admin/companies"

        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /admin/companies/:id" do
    context "when signed in as admin" do
      before do
        get sign_in_for_test_path(email: admin.email)
      end

      it "returns 200 with company JSON" do
        get "/admin/companies/#{company1.id}", headers: json_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["company"]).to be_present
        expect(body["company"]["id"]).to eq(company1.id)
        expect(body["company"]["name"]).to eq(company1.name)
      end

      it "includes owner user data" do
        get "/admin/companies/#{company1.id}", headers: json_headers

        body = JSON.parse(response.body)
        expect(body["company"]["user"]).to be_present
        expect(body["company"]["user"]["id"]).to eq(company1.user.id)
      end

      it "includes business details" do
        get "/admin/companies/#{company1.id}", headers: json_headers

        body = JSON.parse(response.body)
        expect(body["company"]).to have_key("business_type")
        expect(body["company"]).to have_key("workflow_status")
        expect(body["company"]).to have_key("email")
      end

      it "returns 404 for non-existent company" do
        get "/admin/companies/non-existent-id", headers: json_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when signed in as non-admin" do
      before do
        get sign_in_for_test_path(email: company_owner_user.email)
      end

      it "redirects to root" do
        get "/admin/companies/#{company1.id}"

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
