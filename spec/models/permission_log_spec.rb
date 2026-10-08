# frozen_string_literal: true

require "rails_helper"

RSpec.describe PermissionLog, type: :model do
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

  it "belongs to company and optionally to policy/role/appointment/employee" do
    log = build(:permission_log)
    expect(log.company).to be_present
    expect(log.policy).to be_nil
    expect(log.role).to be_nil
    expect(log.policy_role_appointment).to be_nil
    expect(log.employee).to be_nil
  end

  it "requires an action" do
    log = build(:permission_log, action: nil)
    expect(log).not_to be_valid
    expect(log.errors[:action]).to be_present
  end

  it "supports all four actions" do
    expect(described_class.actions.keys).to contain_exactly(
      "granted", "revoked", "conditions_changed", "resource_added"
    )
  end

  it "keeps the log when the policy is destroyed (nullify)" do
    company = create(:company)
    policy = create_policy(company: company)
    log = create(:permission_log, company: company, policy: policy,
      resource_name: policy.resource, policy_action: policy.action, action: :granted)
    policy.destroy!
    expect(log.reload.policy_id).to be_nil
    expect(log.resource_name).to eq("Product")
  end

  it "keeps the log when the appointment is destroyed (nullify)" do
    company = create(:company)
    role = create_role(company: company)
    policy = create_policy(company: company)
    appointment = PolicyRoleAppointment.create!(company: company, policy: policy, role: role)
    log = create(:permission_log, company: company,
      role: role, policy: policy,
      policy_role_appointment: appointment, action: :revoked)
    appointment.destroy!
    expect(log.reload.policy_role_appointment_id).to be_nil
  end
end
