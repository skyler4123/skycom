# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::RolesController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before { get sign_in_for_test_path(email: owner.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "returns roles scoped to the company" do
      role = Seed::RoleService.create(company: company, name: "IndexRole#{SecureRandom.hex(3)}")

      get company_roles_path(company, format: :json)

      names = JSON.parse(response.body)["roles"].map { |r| r["name"] }
      expect(names).to include(role.name, OWNER_BUSINESS_TYPE)
    end
  end

  describe "GET #show" do
    it "returns the role with its paired tag name" do
      role = Seed::RoleService.create(company: company, name: "ShowRole#{SecureRandom.hex(3)}")

      get company_role_path(company, role, format: :json)

      body = JSON.parse(response.body)["role"]
      expect(body["name"]).to eq(role.name)
      expect(body["paired_tag_name"]).to eq("All #{role.name}")
    end

    it "404s for a role from another company" do
      foreign = Seed::RoleService.create(company: create(:company), name: "Foreign#{SecureRandom.hex(3)}")

      get company_role_path(company, foreign, format: :json)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    it "creates a role with its paired system tag and redirects to show" do
      expect {
        post company_roles_path(company),
          params: { role: { name: "NewRole#{SecureRandom.hex(3)}", business_type: "support" } }
      }.to change(Role, :count).by(1)

      role = Role.find_by(company: company, name: Role.last.name)
      expect(NotificationTag.find_by(company: company, name: "All #{role.name}")).to be_present
      expect(response).to redirect_to(company_role_path(company, role))
    end

    it "rejects a duplicate name and creates nothing" do
      existing = Seed::RoleService.create(company: company, name: "DupRole#{SecureRandom.hex(3)}")

      expect {
        post company_roles_path(company),
          params: { role: { name: existing.name, business_type: "support" } }
      }.to change(Role, :count).by(0)

      expect(response).to redirect_to(new_company_role_path(company))
    end
  end

  describe "PATCH #update" do
    it "renames the role and its paired tag and redirects to show" do
      role = Seed::RoleService.create(company: company, name: "Before#{SecureRandom.hex(3)}")

      patch company_role_path(company, role),
        params: { role: { name: "After#{SecureRandom.hex(3)}" } }

      expect(role.reload.name).to start_with("After")
      expect(NotificationTag.find_by(company: company, name: "All #{role.name}")).to be_present
      expect(response).to redirect_to(company_role_path(company, role))
    end
  end

  describe "DELETE #destroy" do
    it "destroys the role and its paired tag and warns in the flash" do
      role = Seed::RoleService.create(company: company, name: "Doomed#{SecureRandom.hex(3)}")
      tag = NotificationTag.find_by(company: company, name: "All #{role.name}")
      expect(tag).to be_present

      expect {
        delete company_role_path(company, role)
      }.to change(Role, :count).by(-1)

      expect(NotificationTag.exists?(tag.id)).to be(false)
      expect(response).to redirect_to(company_roles_path(company))
      expect(flash[:notice]).to match(/removed also/)
    end

    it "refuses to destroy the owner role and keeps the row" do
      owner_role = company.roles.find_by(name: OWNER_BUSINESS_TYPE)

      expect {
        delete company_role_path(company, owner_role)
      }.to change(Role, :count).by(0)

      expect(response).to redirect_to(company_role_path(company, owner_role))
    end

    it "404s for a role from another company" do
      foreign = Seed::RoleService.create(company: create(:company), name: "Foreign#{SecureRandom.hex(3)}")

      expect {
        delete company_role_path(company, foreign)
      }.to change(Role, :count).by(0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "as a non-owner with full Role grants" do
    let!(:branch) { create(:branch, company: company) }
    let!(:manager_role) { Seed::RoleService.create(company: company, name: "StaffManager#{SecureRandom.hex(3)}") }
    let!(:manager_user) { create(:user, :company_employee) }
    let!(:manager_employee) do
      emp = create(:employee, company: company, branch: branch, user: manager_user)
      create(:employee_role_appointment, company: company, employee: emp, role: manager_role)
      emp
    end

    before do
      %w[create read update delete].each do |action|
        policy = Seed::PolicyService.create(
          company: company, name: "Can #{action} Role",
          resource: "Role", action: action,
          business_type: :operational, lifecycle_status: :active
        )
        PolicyRoleAppointment.create!(company: company, policy: policy,
          role: manager_role, workflow_status: :active)
      end
      manager_employee.clear_permissions_cache
      company.clear_permissions_cache
      manager_employee.reload

      get sign_in_for_test_path(email: manager_user.email)
    end

    it "returns 403 on index even with read grant" do
      get company_roles_path(company), as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 on show even with read grant" do
      target = Seed::RoleService.create(company: company, name: "Target#{SecureRandom.hex(3)}")
      get company_role_path(company, target), as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 on create even with create grant" do
      expect {
        post company_roles_path(company),
          params: { role: { name: "Nope#{SecureRandom.hex(3)}", business_type: "support" } }, as: :json
      }.to change(Role, :count).by(0)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 on update even with update grant" do
      target = Seed::RoleService.create(company: company, name: "Locked#{SecureRandom.hex(3)}")
      patch company_role_path(company, target),
        params: { role: { name: "Hacked#{SecureRandom.hex(3)}" } }, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 on destroy even with delete grant" do
      target = Seed::RoleService.create(company: company, name: "Safe#{SecureRandom.hex(3)}")
      expect {
        delete company_role_path(company, target), as: :json
      }.to change(Role, :count).by(0)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
