require "rails_helper"

RSpec.describe "Homepage caching and auth pages", type: :request do
  # Request specs POST without a browser CSRF token — disable forgery for the
  # duration, following the house pattern (see stock_adjustments_spec.rb).
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /" do
    it "is browser-cacheable but never shared (per-session CSRF token in page)" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("private")
      expect(response.headers["Cache-Control"]).to include("max-age=3600")
      expect(response.headers["Cache-Control"]).not_to include("public")
      expect(response.headers["Vary"]).to include("Cookie")
    end

    it "ships the signed-out header statically for SEO" do
      get root_path

      expect(response.body).to include('id="header-guest"')
      expect(response.body).to include('id="header-signedin"')
      expect(response.body).to include("Claim Free Starter Credits")
    end

    it "ships a hidden admin link for admins (revealed client-side by role)" do
      get root_path

      expect(response.body).to include('id="header-admin-link"')
      expect(response.body).to include("/admin/companies")
    end

    it "ships the New Company link hidden (revealed client-side for owners)" do
      get root_path

      expect(response.body).to include('id="header-new-company-link"')
      expect(response.body).to match(/class="hidden [^"]*"\s+href="\/companies\/new"/)
    end

    it "is not cacheable when a flash is present" do
      post sign_in_path, params: { email: "nobody@example.com", password: "wrong" }
      follow_redirect!

      expect(response.body).to include("That email or password is incorrect")
      expect(response.headers["Cache-Control"]).not_to include("max-age=3600")
    end
  end

  describe "GET /sign_in" do
    it "renders the Shell-First shell" do
      get sign_in_path

      expect(response).to have_http_status(:ok)
    end

    it "redirects signed-in users to the homepage" do
      user = create(:user, system_role: :company_owner, password: "Password@1234", password_confirmation: "Password@1234")
      get sign_in_for_test_path(email: user.email)
      get sign_in_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /sign_up" do
    it "renders the Shell-First shell" do
      get sign_up_path

      expect(response).to have_http_status(:ok)
    end

    it "redirects signed-in users to the homepage" do
      user = create(:user, system_role: :company_owner, password: "Password@1234", password_confirmation: "Password@1234")
      get sign_in_for_test_path(email: user.email)
      get sign_up_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /sign_in" do
    it "redirects failures back to the sign-in page" do
      post sign_in_path, params: { email: "nobody@example.com", password: "wrong" }

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "POST /sign_up" do
    it "redirects failures back to the sign-up page" do
      post sign_up_path, params: { email: "bad", password: "x", password_confirmation: "y" }

      expect(response).to redirect_to(sign_up_path)
    end
  end
end
