# app/policies/companies/permissions_policy.rb
class Companies::PermissionsPolicy < ApplicationPolicy
  # NOTE: no show?/destroy? — the controller has no such actions.
  # If one is added, add the matching query here (owner-only like below);
  # Authorizable denies unknown queries by default.
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
