require "rails_helper"

RSpec.describe "CompaniesController#new", type: :request do
  describe "GET /companies/new" do
    it "renders the Shell-First shell for signed-in users" do
      user = create(:user, system_role: :company_owner, password: "Password@1234", password_confirmation: "Password@1234")
      get sign_in_for_test_path(email: user.email)
      get new_company_path

      expect(response).to have_http_status(:ok)
    end

    it "redirects guests to the homepage" do
      get new_company_path

      expect(response).to redirect_to(root_path)
    end
  end
end
