# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::KpiConfigsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:owner_employee) { company.employees.find_by(user: owner) }

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

  let!(:kpi_config) do
    create(:kpi_config, company: company, name: "Orders sold", metric_key: "orders_count", target_value: 10)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "returns configs and options for the owner" do
      get sign_in_for_test_path(email: owner.email)
      get "/companies/#{company.id}/kpi_configs.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["kpi_configs"].first).to include("name" => "Orders sold", "metric_key" => "orders_count")
      expect(body["options"]["metrics"].map { |metric| metric["key"] }).to include("orders_count")
      expect(body["can_manage"]).to be(true)
    end

    it "allows a manager to read" do
      get sign_in_for_test_path(email: manager_user.email)
      get "/companies/#{company.id}/kpi_configs.json"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["can_manage"]).to be(false)
    end

    it "forbids an employee without the permission" do
      employee_user = create(:user, :company_employee)
      create(:employee, company: company, user: employee_user)

      get sign_in_for_test_path(email: employee_user.email)
      get "/companies/#{company.id}/kpi_configs.json"

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to include("errors" => [ "You are not authorized to perform this action." ])
    end
  end

  describe "POST #create" do
    it "creates a config for the owner" do
      get sign_in_for_test_path(email: owner.email)

      expect do
        post "/companies/#{company.id}/kpi_configs.json", params: {
          kpi_config: {
            name: "Revenue",
            metric_key: "orders_revenue_cents",
            target_value: 100_000,
            weight: 2,
            period_type: "month",
            direction: "higher_better"
          }
        }
      end.to change(KpiConfig, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("KPI created successfully")
      expect(body["kpi_config"]).to include("name" => "Revenue")
    end

    it "returns errors for invalid input" do
      get sign_in_for_test_path(email: owner.email)

      post "/companies/#{company.id}/kpi_configs.json", params: {
        kpi_config: { name: "", metric_key: "unknown" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "forbids a manager from creating" do
      get sign_in_for_test_path(email: manager_user.email)

      expect do
        post "/companies/#{company.id}/kpi_configs.json", params: {
          kpi_config: { name: "Blocked", metric_key: "orders_count" }
        }
      end.not_to change(KpiConfig, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH #update" do
    it "updates the config for the owner" do
      get sign_in_for_test_path(email: owner.email)

      patch "/companies/#{company.id}/kpi_configs/#{kpi_config.id}.json", params: {
        kpi_config: { target_value: 25 }
      }

      expect(response).to have_http_status(:ok)
      expect(kpi_config.reload.target_value).to eq(25)
    end

    it "forbids a manager from updating" do
      get sign_in_for_test_path(email: manager_user.email)

      patch "/companies/#{company.id}/kpi_configs/#{kpi_config.id}.json", params: {
        kpi_config: { target_value: 25 }
      }

      expect(response).to have_http_status(:forbidden)
      expect(kpi_config.reload.target_value).to eq(10)
    end
  end

  describe "DELETE #destroy" do
    it "deletes the config for the owner" do
      get sign_in_for_test_path(email: owner.email)

      expect do
        delete "/companies/#{company.id}/kpi_configs/#{kpi_config.id}.json"
      end.to change(KpiConfig, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("KPI deleted successfully")
    end

    it "forbids a manager from deleting" do
      get sign_in_for_test_path(email: manager_user.email)

      expect do
        delete "/companies/#{company.id}/kpi_configs/#{kpi_config.id}.json"
      end.not_to change(KpiConfig, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
