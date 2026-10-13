# app/policies/companies/roles_policy.rb
#
# Owner-only resource: ONLY the company owner (owner-role employee) may CRUD
# roles. Grants are deliberately ignored — roles own their "All <Role>"
# system broadcast tags, so letting a grantee delete roles would let them
# silently destroy other audiences' notification subscriptions. Do NOT add
# Role entries to seed role_definitions; they would be inert but misleading.
class Companies::RolesPolicy < ApplicationPolicy
  def index?
    record.owner_role?
  end

  def show?
    record.owner_role?
  end

  def new?
    record.owner_role?
  end

  def create?
    record.owner_role?
  end

  def edit?
    record.owner_role?
  end

  def update?
    record.owner_role?
  end

  def destroy?
    record.owner_role?
  end
end
