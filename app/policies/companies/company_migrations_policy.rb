# Owner-only by design: importing writes straight into business tables, and
# the policy record is the current employee — so every action checks
# owner_role? directly. Deliberately NOT registered in
# Company::DEFAULT_RESOURCE_NAMES: seeding would auto-grant Admin/Manager
# CRUD policies and silently widen access.
class Companies::CompanyMigrationsPolicy < ApplicationPolicy
  def index?
    record.owner_role?
  end

  def show?
    record.owner_role?
  end

  def create?
    record.owner_role?
  end

  def destroy?
    record.owner_role?
  end

  def update_config?
    record.owner_role?
  end

  def chunks?
    record.owner_role?
  end

  def dry_run?
    record.owner_role?
  end

  def approve?
    record.owner_role?
  end

  def rollback?
    record.owner_role?
  end
end
