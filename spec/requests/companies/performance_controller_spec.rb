# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PerformanceController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:range_from) { Time.zone.parse("2026-03-01 00:00:00") }
  let(:range_to) { Time.zone.parse("2026-03-31 23:59:59") }
  let(:in_range) { Time.zone.parse("2026-03-15 10:00:00") }

  let!(:employee_user) { create(:user, :company_employee) }
  let!(:employee) { create(:employee, company: company, user: employee_user) }
  let!(:kpi_config) do
    create(:kpi_config, company: company, name: "Orders sold", metric_key: "orders_count",
      target_value: 10, period_type: :month)
  end

  let!(:manager_role) { create(:role, company: company, name: "Manager") }
  let!(:manager_user) { create(:user, :company_employee) }
  let!(:manager_employee) { create(:employee, company: company, user: manager_user) }
  let!(:manager_appointment) do
    create(:employee_role_appointment, company: company, employee: manager_employee, role: manager_role)
  end
  let!(:read_policy) do
    Seed::PolicyService.create(
      company: company,
      name: "Can read KpiConfig",
      resource: "KpiConfig",
      action: "read",
      business_type: :operational,
      lifecycle_status: :active
    )
  end
  let!(:policy_appointment) do
    create(:policy_role_appointment, company: company, role: manager_role, policy: read_policy,
      workflow_status: :active)
  end

  before do
    create_paid_order(company: company, salesperson: employee, created_at: in_range)
    create_paid_order(company: company, salesperson: employee, created_at: in_range)
    create_paid_order(company: company, salesperson: nil, created_at: in_range)
    create_paid_order(company: company, salesperson: employee, created_at: in_range - 1.month)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "returns the leaderboard and unattributed orders for the owner" do
      get sign_in_for_test_path(email: owner.email)
      get "/companies/#{company.id}/performance.json",
        params: { period: "custom", from: "2026-03-01", to: "2026-03-31" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["rows"].find { |row| row["employee_id"] == employee.id }["composite_pct"]).to eq(20.0)
      expect(body["unattributed"]).to include("orders_count" => 1, "revenue_cents" => 5000)
      expect(body["can_manage"]).to be(true)
    end

    it "allows a manager to read" do
      get sign_in_for_test_path(email: manager_user.email)
      get "/companies/#{company.id}/performance.json"

      expect(response).to have_http_status(:ok)
    end

    it "forbids an employee without the permission" do
      get sign_in_for_test_path(email: employee_user.email)
      get "/companies/#{company.id}/performance.json"

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to include("errors" => [ "You are not authorized to perform this action." ])
    end
  end

  describe "GET #show" do
    it "returns the employee scorecard for the owner" do
      get sign_in_for_test_path(email: owner.email)
      get "/companies/#{company.id}/performance/#{employee.id}.json",
        params: { period: "custom", from: "2026-03-01", to: "2026-03-31" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["employee"]).to include("id" => employee.id)
      expect(body["rows"].first["actual_value"]).to eq(2)
      expect(body["composite_pct"]).to eq(20.0)
    end

    it "returns 404 for an employee outside the company" do
      other_employee = create(:employee)

      get sign_in_for_test_path(email: owner.email)
      get "/companies/#{company.id}/performance/#{other_employee.id}.json"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["errors"]).to include("Employee not found")
    end
  end
end
