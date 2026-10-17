require "rails_helper"

RSpec.describe "CompaniesController#new", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  # Signs in a company_employee who belongs to an existing company (the
  # "manager employee" case) and returns their user.
  def sign_in_employee_belonging_to_company
    company = create(:company, user: create(:user, :company_owner))
    employee_user = create(:user)
    create(:employee, company: company, user: employee_user)
    get sign_in_for_test_path(email: employee_user.email)
    employee_user
  end

  describe "GET /companies/new" do
    it "renders the Shell-First shell for signed-in users" do
      user = create(:user, system_role: :company_owner, password: "Password@1234", password_confirmation: "Password@1234")
      get sign_in_for_test_path(email: user.email)
      get new_company_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the Shell-First shell for a user who does not belong to any company yet" do
      fresh_user = create(:user)
      get sign_in_for_test_path(email: fresh_user.email)

      get new_company_path

      expect(response).to have_http_status(:ok)
    end

    it "redirects company members to the homepage with an alert" do
      sign_in_employee_belonging_to_company

      get new_company_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end

    it "returns 403 with an errors array for company members (JSON)" do
      sign_in_employee_belonging_to_company

      get new_company_path(format: :json)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["errors"]).to contain_exactly("You are not authorized to perform this action.")
    end

    it "redirects guests to the homepage" do
      get new_company_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /companies" do
    let(:user) { create(:user, system_role: :company_owner, password: "Password@1234", password_confirmation: "Password@1234") }

    before { get sign_in_for_test_path(email: user.email) }

    it "creates a company with us country and maps currency to usd" do
      expect {
        post companies_path, params: { company: { name: "US Co #{SecureRandom.hex(4)}", business_type: :retail, country: :us } }
      }.to change(Company, :count).by(1)
      company = Company.order(:created_at).last
      expect(company.country).to eq("us")
      expect(company.currency).to eq("usd")
      expect(response).to redirect_to(company_dashboards_path(company))
    end

    it "creates a company with vn country and maps currency to vnd" do
      expect {
        post companies_path, params: { company: { name: "VN Co #{SecureRandom.hex(4)}", business_type: :retail, country: :vn } }
      }.to change(Company, :count).by(1)
      company = Company.order(:created_at).last
      expect(company.country).to eq("vn")
      expect(company.currency).to eq("vnd")
    end

    it "rejects creation without a country" do
      expect {
        post companies_path, params: { company: { name: "No Country Co #{SecureRandom.hex(4)}", business_type: :retail } }
      }.not_to change(Company, :count)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/country/i)
    end

    it "blocks a company member without creating a company or promoting them" do
      employee_user = sign_in_employee_belonging_to_company

      expect {
        post companies_path, params: { company: { name: "Manager Co #{SecureRandom.hex(4)}", business_type: :retail, country: :us } }
      }.not_to change(Company, :count)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      expect(employee_user.reload.system_role).to eq("company_employee")
    end
  end
end
