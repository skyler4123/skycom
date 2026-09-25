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
