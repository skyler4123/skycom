# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::EmployeeSubprofilesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "employee_subprofiles" }
    let(:index_class) { EmployeeSubprofile }
    let(:json_key) { "employee_subprofiles" }
    let(:base_json_path) { "/companies/#{company.id}/employee_subprofiles.json" }
    let(:record) do
      lambda do |company:, category:, **attrs|
        employee = Employee.find_by(company: company) || create(:employee, company: company)
        profile_category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_profiles")
        profile = EmployeeProfile.find_by(company: company, employee: employee) ||
          Seed::EmployeeProfileService.create(company: company, employee: employee, category: profile_category, name: "Profile #{SecureRandom.hex(4)}")
        Seed::EmployeeSubprofileService.create(company: company, employee: employee, employee_profile: profile, category: category, **attrs)
      end
    end
  end
end

RSpec.describe "Companies::EmployeeSubprofilesController CRUD", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_subprofiles") }
  let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_profiles") }
  let(:employee) { create(:employee, company: company) }
  let(:profile) { Seed::EmployeeProfileService.create(company: company, employee: employee, category: profile_category, name: "Profile 1") }

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
    let!(:sub) { Seed::EmployeeSubprofileService.create(company: company, employee: employee, employee_profile: profile, category: category, name: "Subprofile 11") }

    it "returns subprofiles" do
      get "/companies/#{company.id}/employee_subprofiles.json", params: { category_id: category.id }
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["employee_subprofiles"].map { |c| c["id"] }
      expect(ids).to include(sub.id)
    end

    it "filters by employee_profile_id" do
      profile2 = Seed::EmployeeProfileService.create(company: company, employee: employee, category: profile_category, name: "Profile 2")
      Seed::EmployeeSubprofileService.create(company: company, employee: employee, employee_profile: profile2, category: category, name: "Subprofile 21")
      get "/companies/#{company.id}/employee_subprofiles.json", params: { employee_profile_id: profile.id }
      names = JSON.parse(response.body)["employee_subprofiles"].map { |c| c["name"] }
      expect(names).to include("Subprofile 11")
      expect(names).not_to include("Subprofile 21")
    end
  end

  describe "POST create" do
    it "creates and redirects on success" do
      expect {
        post "/companies/#{company.id}/employee_subprofiles",
          params: { employee_subprofile: { name: "Subprofile 11", employee_id: employee.id, employee_profile_id: profile.id, category_id: category.id, business_type: "general" } }
      }.to change(EmployeeSubprofile, :count).by(1)
    end

    it "fails when employee mismatches profile" do
      other = create(:employee, company: company)
      expect {
        post "/companies/#{company.id}/employee_subprofiles",
          params: { employee_subprofile: { name: "Bad", employee_id: other.id, employee_profile_id: profile.id, category_id: category.id, business_type: "general" } }
      }.not_to change(EmployeeSubprofile, :count)
      expect(response).to have_http_status(:found)
    end
  end
end
