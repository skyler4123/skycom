# frozen_string_literal: true

# Employee::ManagerConcern — Atomic purpose: resolves the managers an employee
# reports to through their EmployeeGroup memberships.
#
# Why it exists: reporting lines live on EmployeeGroup (one manager per team),
# so an employee can have several managers across teams, and the lookup should be
# cached instead of joining on every mobile render.
# How it works: managers reads the group manager ids from Rails.sync_cache for
# CACHE_DEFAULT_EXPIRY, then loads the kept employees; membership and group
# manager changes clear the key.
# Main associations: none directly; reads Employee#employee_groups and
# EmployeeGroup#manager.
module Employee::ManagerConcern
  extend ActiveSupport::Concern

  def managers
    return Employee.none if id.blank?

    Employee.kept.where(id: manager_ids).where.not(id: id).order(:name, :id)
  end

  def clear_managers_cache
    Rails.sync_cache.delete(CacheKeyService.employee_manager_ids(id))
  end

  private

  def manager_ids
    Rails.sync_cache.fetch(
      CacheKeyService.employee_manager_ids(id),
      expires_in: CACHE_DEFAULT_EXPIRY
    ) do
      employee_groups.where.not(manager_id: nil).distinct.pluck(:manager_id)
    end
  end
end
