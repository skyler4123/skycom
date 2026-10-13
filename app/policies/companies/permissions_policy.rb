# app/policies/companies/permissions_policy.rb
class Companies::PermissionsPolicy < ApplicationPolicy
  def index?
    # Owner-only: no role grants can open Permissions (mirrors RolesPolicy).
    record.owner_role?
  end

  def create?
    record.owner_role?
  end

  def update?
    record.owner_role?
  end
end
