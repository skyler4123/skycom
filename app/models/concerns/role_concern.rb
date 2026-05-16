module RoleConcern
  extend ActiveSupport::Concern

  included do
    def attach_role(name)
      raise "Model must belong to a company to attach a tag." unless respond_to?(:company) && company

      ApplicationRecord.transaction do
        role = company.roles.find_or_create_by!(name: name)

        unless roles.include?(role)
          role_appointments.create!(
            company: company,
            role: role,
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
