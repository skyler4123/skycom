# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CompanySettingsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  describe "GET /companies/:company_id/company_settings" do
    it "returns an empty list when the company has no settings" do
      get "/companies/#{company.id}/company_settings", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["company_settings"]).to eq([])
    end

    it "returns company settings when they exist" do
      record = CompanySetting.create!(
        company: company, name: "Links", business_type: :sidebar_groups, workflow_status: :active
      )

      get "/companies/#{company.id}/company_settings", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["company_settings"].map { |s| s["id"] }).to eq([ record.id ])
    end
  end

  describe "PATCH /companies/:company_id/company_settings/:id" do
    let!(:record) do
      CompanySetting.create!(
        company: company, name: "Links", business_type: :sidebar_groups,
        workflow_status: :active, sidebar_groups: []
      )
    end

    it "updates sidebar_groups as the owner" do
      groups = [
        { "key" => "my-links", "name" => "My Links",
          "items" => [ { "key" => "pending", "name" => "Pending Orders", "url" => "/orders?workflow_status=pending" } ] }
      ]
      patch "/companies/#{company.id}/company_settings/#{record.id}",
        params: { company_setting: { metadata: { sidebar_groups: groups } } }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["company_setting"]["metadata"]["sidebar_groups"]).to eq(groups)
      expect(record.reload.sidebar_groups).to eq(groups)
    end

    it "returns 422 with errors for invalid sidebar_groups" do
      patch "/companies/#{company.id}/company_settings/#{record.id}",
        params: { company_setting: { metadata: { sidebar_groups: [ { "key" => "g1" } ] } } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns 422 when activating a second setting with the same business_type" do
      CompanySetting.create!(
        company: company, name: "Links v2", business_type: :sidebar_groups, workflow_status: :inactive
      )
      second = CompanySetting.where(company: company, name: "Links v2").first

      patch "/companies/#{company.id}/company_settings/#{second.id}",
        params: { company_setting: { workflow_status: "active" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns 404 for a setting from another company" do
      other_company = create(:company)
      foreign = CompanySetting.create!(
        company: other_company, name: "Links", business_type: :sidebar_groups, workflow_status: :active
      )

      patch "/companies/#{company.id}/company_settings/#{foreign.id}",
        params: { company_setting: { metadata: { sidebar_groups: [] } } }, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns 403 for an employee without update permission" do
      employee = create(:employee, company: company)
      company.clear_permissions_cache
      get sign_in_for_test_path(email: employee.user.email)

      patch "/companies/#{company.id}/company_settings/#{record.id}",
        params: { company_setting: { metadata: { sidebar_groups: [] } } }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns 403 on update even with update grant (owner-only)" do
      branch = create(:branch, company: company)
      manager_role = Seed::RoleService.create(company: company, name: "SettingsManager#{SecureRandom.hex(3)}")
      manager_user = create(:user)
      manager_employee = create(:employee, company: company, branch: branch, user: manager_user)
      create(:employee_role_appointment, company: company, employee: manager_employee, role: manager_role)

      %w[create read update delete].each do |action|
        policy = Seed::PolicyService.create(
          company: company, name: "Can #{action} CompanySetting",
          resource: "CompanySetting", action: action,
          business_type: :operational, lifecycle_status: :active
        )
        PolicyRoleAppointment.create!(company: company, policy: policy,
          role: manager_role, workflow_status: :active)
      end
      manager_employee.clear_permissions_cache
      company.clear_permissions_cache
      manager_employee.reload

      get sign_in_for_test_path(email: manager_user.email)

      groups = [
        { "key" => "my-links", "name" => "My Links",
          "items" => [ { "key" => "pending", "name" => "Pending Orders", "url" => "/orders" } ] }
      ]
      patch "/companies/#{company.id}/company_settings/#{record.id}",
        params: { company_setting: { metadata: { sidebar_groups: groups } } }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"]).to be_present
      expect(record.reload.sidebar_groups).to eq([])
    end
  end
end
