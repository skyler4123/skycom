module RoleConcern
  extend ActiveSupport::Concern

  included do
    def attach_role(name)
      # Ensure the object has a 'company' association for proper tag scoping
      raise "Model must belong to a company to attach a tag." unless respond_to?(:company_group) && company_group

      ApplicationRecord.transaction do
        # 1. Find or create the Role scoped to the company group
        role = company_group.roles.find_or_create_by!(name: name)

        # 2. Assign the role to the resource if not already assigned
        unless roles.include?(role)
          self.roles << role
        end

        role # Return the resulting role
      end
    rescue ActiveRecord::RecordInvalid => e
      # Provides context for which record failed validation
      Rails.logger.error "Role assignment failed for #{self.class} #{self.id} with role '#{name}': #{e.message}"
      raise e # Re-raise the error for standard Rails handling
    end

    def has_role?(role_name)
      roles.exists?(name: role_name)
    end
  end
end
