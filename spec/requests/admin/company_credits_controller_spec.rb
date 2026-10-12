require "rails_helper"

RSpec.describe "Admin::CompanyCredits", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:company_owner_user) { create(:user, :company_owner) }
  let!(:company1) { create(:company) }

  let(:json_headers) { { "ACCEPT" => "application/json" } }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /admin/company_credits" do
    context "when signed in as admin" do
      before { get sign_in_for_test_path(email: admin.email) }

      it "returns wallet balances with pagination" do
        get "/admin/company_credits", headers: json_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        row = body["company_credits"].find { |c| c["id"] == company1.id }
        expect(row).to include("promo_credit_balance", "main_credit_balance",
          "debt_credit_balance", "total_credit_balance", "owner_name")
        expect(body["pagination"]).to be_present
      end

      it "filters by country" do
        company1.update!(country: :us)
        other = create(:company)
        other.update!(country: :vn)

        get "/admin/company_credits", params: { country: "us" }, headers: json_headers

        body = JSON.parse(response.body)
        ids = body["company_credits"].map { |c| c["id"] }
        expect(ids).to include(company1.id)
        expect(ids).not_to include(other.id)
      end

      it "searches by name" do
        company1.update!(name: "Acme Rocket Corp")

        get "/admin/company_credits", params: { q: "Rocket" }, headers: json_headers

        body = JSON.parse(response.body)
        expect(body["company_credits"].map { |c| c["id"] }).to include(company1.id)
      end
    end

    context "when signed in as non-admin" do
      before { get sign_in_for_test_path(email: company_owner_user.email) }

      it "redirects to root" do
        get "/admin/company_credits"

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
