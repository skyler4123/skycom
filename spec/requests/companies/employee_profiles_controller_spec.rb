# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::EmployeeProfilesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "employee_profiles" }
    let(:index_class) { EmployeeProfile }
    let(:json_key) { "employee_profiles" }
    let(:base_json_path) { "/companies/#{company.id}/employee_profiles.json" }
    let(:record) do
      lambda do |company:, category:, **attrs|
        employee = Employee.find_by(company: company) || create(:employee, company: company)
        Seed::EmployeeProfileService.create(company: company, employee: employee, category: category, **attrs)
      end
    end
  end
end

RSpec.describe "Companies::EmployeeProfilesController CRUD", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_profiles") }
  let(:employee) { create(:employee, company: company) }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET index" do
    let!(:profile) { Seed::EmployeeProfileService.create(company: company, employee: employee, category: category, name: "Profile 1") }

    it "returns profiles" do
      get "/companies/#{company.id}/employee_profiles.json", params: { category_id: category.id }
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["employee_profiles"].map { |c| c["id"] }
      expect(ids).to include(profile.id)
    end

    it "filters by employee_id" do
      other = create(:employee, company: company)
      Seed::EmployeeProfileService.create(company: company, employee: other, category: category, name: "Profile X")
      get "/companies/#{company.id}/employee_profiles.json", params: { employee_id: employee.id }
      names = JSON.parse(response.body)["employee_profiles"].map { |c| c["name"] }
      expect(names).to include("Profile 1")
      expect(names).not_to include("Profile X")
    end
  end

  describe "POST create" do
    it "creates and redirects on success" do
      expect {
        post "/companies/#{company.id}/employee_profiles",
          params: { employee_profile: { name: "Profile 1", employee_id: employee.id, category_id: category.id, business_type: "general" } }
      }.to change(EmployeeProfile, :count).by(1)
      created = EmployeeProfile.find_by(name: "Profile 1")
      expect(response).to redirect_to("/companies/#{company.id}/employee_profiles/#{created.id}")
    end

    it "redirects with alert on failure and creates nothing" do
      expect {
        post "/companies/#{company.id}/employee_profiles",
          params: { employee_profile: { name: "", employee_id: employee.id, category_id: category.id } }
      }.not_to change(EmployeeProfile, :count)
      expect(response).to have_http_status(:found)
    end
  end

  describe "PATCH update" do
    let!(:profile) { Seed::EmployeeProfileService.create(company: company, employee: employee, category: category, name: "Profile 1") }

    it "updates and redirects on success" do
      patch "/companies/#{company.id}/employee_profiles/#{profile.id}",
        params: { employee_profile: { name: "Profile Renamed" } }
      expect(profile.reload.name).to eq("Profile Renamed")
      expect(response).to redirect_to("/companies/#{company.id}/employee_profiles/#{profile.id}")
    end

    it "fails with blank name" do
      patch "/companies/#{company.id}/employee_profiles/#{profile.id}",
        params: { employee_profile: { name: "" } }, headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end
end
