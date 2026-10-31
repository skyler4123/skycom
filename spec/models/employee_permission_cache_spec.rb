# spec/models/employee_permission_cache_spec.rb
require "rails_helper"

RSpec.describe "Employee permission cache keys", type: :model do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }
  let(:role) { create(:role, company: company, name: "Cache Test Role") }
  let(:branch) { create(:branch, company: company) }
  let(:policy) do
    Seed::PolicyService.create(
      branch: branch,
      name: "Can read CacheTestResource",
      resource: "CacheTestResource",
      action: "read"
    )
  end
  let!(:employee_role_appointment) do
    create(:employee_role_appointment, company: company, employee: employee, role: role)
  end
  let!(:policy_role_appointment) do
    create(:policy_role_appointment, company: company, role: role, policy: policy, workflow_status: :active)
  end

  it "caches permissions_by_role under the service key" do
    employee.permissions_by_role

    expect(Rails.sync_cache.read(CacheKeyService.employee_permissions_by_role(employee))).to be_present
  end

  it "invalidates the employee record and permission key when a policy grant changes" do
    record_key = CacheKeyService.employee_record(
      user_id: employee.user_id,
      company_id: employee.company_id
    )
    employee.send(:refresh_cache)
    employee.permissions_by_role
    old_permission_key = CacheKeyService.employee_permissions_by_role(employee)
    cached_before = Rails.sync_cache.read(record_key)
    expect(cached_before).to be_present
    expect(Rails.sync_cache.read(old_permission_key)).to be_present

    policy_role_appointment.update!(workflow_status: :inactive)

    cached_after = Rails.sync_cache.read(record_key)
    record_is_fresh = cached_after.nil? || cached_after["updated_at"] != cached_before["updated_at"]
    expect(record_is_fresh).to be(true), "employee record cache kept a stale updated_at"

    employee.reload
    expect(employee.permissions_by_role[role.name][:policies]).to be_empty
    expect(CacheKeyService.employee_permissions_by_role(employee)).not_to eq(old_permission_key)
  end

  it "clears the permission keys on clear_permissions_cache" do
    employee.permissions
    employee.permissions_by_role
    permissions_key = CacheKeyService.employee_permissions(employee)
    by_role_key = CacheKeyService.employee_permissions_by_role(employee)
    expect(Rails.sync_cache.read(permissions_key)).not_to be_nil
    expect(Rails.sync_cache.read(by_role_key)).not_to be_nil

    employee.clear_permissions_cache

    expect(Rails.sync_cache.read(permissions_key)).to be_nil
    expect(Rails.sync_cache.read(by_role_key)).to be_nil
  end
end
