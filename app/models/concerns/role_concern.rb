# == Purpose:
# Gives any role-holder record (Employee, Customer, Department, ...) a uniform
# way to receive roles. Each holder owns exactly one atomic table
# (<Holder>RoleAppointment — Role sorts last alphabetically).
#
# == How It Works:
# 1. attach_role finds-or-creates the company-scoped Role, then checks the
#    holder's concrete atomic table directly (roles may be memoized and miss
#    just-created rows) and creates the row with lifecycle_status :active —
#    all inside one transaction.
# 2. has_role? is a thin exists? check against the holder's roles association.
# 3. company_id on new rows derives from the holder via
#    SetDefaultCompanyConcern; owner rows are immutable (see the atomic model).
#
# == Usage:
# Include in any role-holder model; call record.attach_role("Manager") and
# record.has_role?("Manager"). Never create atomic rows directly.
#
# == Example:
#   employee.attach_role("Cashier")
#   employee.has_role?("Cashier") # => true
#
module RoleConcern
  extend ActiveSupport::Concern

  included do
    def attach_role(name)
      raise "Model must belong to a company to attach a tag." unless respond_to?(:company) && company

      ApplicationRecord.transaction do
        role = company.roles.find_or_create_by!(name: name) do |r|
          r.business_type ||= Role.business_types.keys.reject { |k| k == OWNER_BUSINESS_TYPE }.sample
        end

        # Atomic pairwise table, e.g. Employee => EmployeeRoleAppointment,
        # Customer => CustomerRoleAppointment (Role sorts last alphabetically).
        # Query the table directly: `roles` may be memoized and miss just-created rows.
        appointment_class = "#{self.class.name}RoleAppointment".constantize
        foreign_key = "#{self.class.name.underscore}_id"
        exists = appointment_class.exists?(
          company_id: company.id, role_id: role.id, foreign_key => id
        )

        unless exists
          appointment_class.create!(
            company: company,
            role: role,
            foreign_key => id,
            lifecycle_status: :active
          )
        end

        role
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Role assignment failed for #{self.class} #{self.id} with role '#{name}': #{e.message}"
      raise e
    end

    def has_role?(role_name)
      roles.exists?(name: role_name)
    end
  end
end
