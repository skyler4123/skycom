# frozen_string_literal: true

# == Purpose:
# Automatically sets +company_id+ on Appointment records by deriving it from
# the associated resource (Role, Policy, Tag, Service, Task, etc.).
#
# This ensures ABAC permission checks work correctly since they depend on
# +company_id+ being present for multi-tenant security. Without this concern,
# creating an appointment like +RoleAppointment.create!(role: some_role)+ would
# fail because company_id would be nil.
#
# == How It Works (atomic appointments):
# 1. For atomic A_B_Appointment (e.g. EmployeeRoleAppointment), tries each
#    belongs_to association (employee, role, company) in order and uses the
#    first one that responds to company_id.
# 2. Only sets company_id if not already present.
#
# == Usage:
# Include this concern in any *_appointment model with two concrete FKs
# (e.g., belongs_to :employee, belongs_to :role).
#
# == Example:
#   class EmployeeRoleAppointment < ApplicationRecord
#     include SetDefaultCompanyConcern
#     belongs_to :company
#     belongs_to :employee
#     belongs_to :role
#   end
#
module SetDefaultCompanyConcern
  extend ActiveSupport::Concern

  included do
    before_validation :set_default_company_from_resource
  end

  private

  def set_default_company_from_resource
    return if respond_to?(:company) && (company.present? || company_id.present?)
    # Models without company column (e.g. AddressCompanyAppointment has company as pair side)
    # still derive from pair sides if possible.
    resource = find_resource_association
    return if resource.blank?
    return unless resource.respond_to?(:company_id)
    return unless respond_to?(:company_id=)

    self.company_id = resource.company_id
  end

  # Tries all belongs_to associations (except company itself) and returns the
  # first record that can provide a company_id. Falls back to company pair side.
  def find_resource_association
    candidates = self.class.reflect_on_all_associations(:belongs_to).map(&:name) - [ :company ]
    candidates.each do |assoc|
      next unless respond_to?(assoc)
      rec = public_send(assoc)
      next if rec.blank?
      return rec if rec.respond_to?(:company_id)
      # Company pair side itself (e.g. AddressCompanyAppointment#company is a Company)
      return rec if rec.is_a?(Company)
    end
    # Fallback: company pair side
    return company if respond_to?(:company) && company.present?
    nil
  end
end
