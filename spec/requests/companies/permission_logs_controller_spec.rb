# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PermissionLogsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  def create_policy(company:, resource: "Product", action: "read")
    Seed::PolicyService.create(
      company: company,
      name: "Can #{action} #{resource}",
      resource: resource,
      action: action,
      business_type: :operational,
      lifecycle_status: :active
    )
  end

  def create_role(company:, name: "Auditor")
    Seed::RoleService.create(company: company, name: name, business_type: :management)
  end

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "returns logs scoped to the company with actor info" do
      role = create_role(company: company)
      policy = create_policy(company: company)
      log = PermissionLogs::WriteService.call(
        company: company, action: :granted,
        actor: company.employees.first,
        role: role, policy: policy
      )

      get "/companies/#{company.id}/permission_logs.json"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      ids = body["permission_logs"].map { |l| l["id"] }
      expect(ids).to include(log.id)
      expect(body).to have_key("filters")
    end

    it "filters by role and action" do
      role = create_role(company: company)
      other_role = create_role(company: company, name: "Viewer")
      keep = create(:permission_log, company: company, role: role,
        role_name: role.name, action: :granted)
      drop = create(:permission_log, company: company, role: other_role,
        role_name: other_role.name, action: :revoked)

      get "/companies/#{company.id}/permission_logs.json",
        params: { role_id: role.id, log_action: "granted" }
      ids = JSON.parse(response.body)["permission_logs"].map { |l| l["id"] }
      expect(ids).to include(keep.id)
      expect(ids).not_to include(drop.id)
    end

    it "does not leak logs from other companies" do
      other = create(:company)
      foreign = create(:permission_log, company: other, action: :granted)

      get "/companies/#{company.id}/permission_logs.json"
      ids = JSON.parse(response.body)["permission_logs"].map { |l| l["id"] }
      expect(ids).not_to include(foreign.id)
    end
  end

  describe "GET #show" do
    it "returns the log snapshot with before/after conditions" do
      log = create(:permission_log, company: company, action: :conditions_changed,
        employee_name: "Jane", metadata: {
          "tag_conditions_before" => {}, "tag_conditions_after" => { "brand" => "Apple" }
        })

      get "/companies/#{company.id}/permission_logs/#{log.id}.json"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["permission_log"]
      expect(body["metadata"]["tag_conditions_after"]).to eq({ "brand" => "Apple" })
      expect(body["employee"]["name"]).to eq("Jane")
    end

    it "404s for a foreign company's log" do
      other = create(:company)
      foreign = create(:permission_log, company: other, action: :granted)

      get "/companies/#{other.id}/permission_logs/#{foreign.id}.json"
      # signed in as company owner, other company is out of scope
      expect(response).not_to have_http_status(:ok)
    end
  end

  describe "audit writes from PermissionsController" do
    let!(:role) { create_role(company: company, name: "Seller") }
    let!(:policy) do
      create_policy(company: company, resource: "Order", action: "read")
    end
    let!(:appointment) do
      PolicyRoleAppointment.create!(company: company, policy: policy, role: role,
        workflow_status: :inactive)
    end

    it "writes a granted log when toggling active" do
      expect {
        patch "/companies/#{company.id}/permissions/#{appointment.id}",
          params: { policy_appointment: { workflow_status: true } }, as: :json
      }.to change { PermissionLog.where(company: company).count }.by(1)

      log = PermissionLog.where(company: company).order(:created_at).last
      expect(log.action).to eq("granted")
      expect(log.role_id).to eq(role.id)
      expect(log.policy_id).to eq(policy.id)
      expect(log.from_workflow_status).to eq(PolicyRoleAppointment.workflow_statuses["inactive"])
      expect(log.to_workflow_status).to eq(PolicyRoleAppointment.workflow_statuses["active"])
    end

    it "writes a conditions_changed log when editing tag conditions" do
      expect {
        patch "/companies/#{company.id}/permissions/#{appointment.id}",
          params: { policy: { metadata: { tag_conditions: { brand: "Apple" } } } }
      }.to change { PermissionLog.where(company: company).count }.by(1)

      log = PermissionLog.where(company: company).order(:created_at).last
      expect(log.action).to eq("conditions_changed")
      expect(log.metadata["tag_conditions_after"]).to eq({ "brand" => "Apple" })
    end

    it "writes resource_added logs when adding a resource to a role" do
      fresh_role = create_role(company: company, name: "FreshRole")
      expect {
        post "/companies/#{company.id}/permissions",
          params: { permission: { role_id: fresh_role.id, resource_name: "Supplier" } }
      }.to change { PermissionLog.where(company: company, action: "resource_added").count }.by(4)

      log = PermissionLog.where(company: company, action: "resource_added").order(:created_at).last
      expect(log.resource_name).to eq("Supplier")
      expect(log.role_id).to eq(fresh_role.id)
    end
  end

  describe "read-only routes" do
    it "does not route POST/PUT/DELETE" do
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/permission_logs", method: :post)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/permission_logs/1", method: :patch)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/permission_logs/1", method: :delete)
      }.to raise_error(ActionController::RoutingError)
    end
  end
end
