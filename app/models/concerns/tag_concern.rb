# Provides instance methods for attaching and managing Tags on a resource
# that uses a polymorphic TagAppointment association (AWS-style tagging).
module TagConcern
  extend ActiveSupport::Concern

  included do
    # Assigns a new tag or updates the value of an existing tag key on the resource.
    # This method is transactional to ensure atomic creation/update.
    #
    # @param name [String] The name (key) of the tag.
    # @param value [String, nil] The value to assign to the tag.
    # @param description [String, nil] An optional description for the appointment.
    # @return [TagAppointment] The created or updated TagAppointment instance.
    def attach_tag(name:, value: nil, description: nil)
      # Ensure the object has a 'company' association for proper tag scoping
      raise "Model must belong to a company to attach a tag." unless respond_to?(:company) && company

      ApplicationRecord.transaction do
        # 1. Find or create the Tag (the Key) scoped to the company
        tag = company.tags.find_or_create_by!(name: name)

        # 2. Find or initialize the TagAppointment (the Assignment).
        # This handles the uniqueness constraint: only one Appointment per (Tag + Resource).
        appointment = tag_appointments.find_or_initialize_by(tag: tag)
        
        # 3. Update the fields
        appointment.value = value
        appointment.description = description

        # 4. Save the appointment (creates if new, updates if existing)
        appointment.save!
        
        appointment # Return the resulting appointment
      end
    rescue ActiveRecord::RecordInvalid => e
      # Provides context for which record failed validation
      Rails.logger.error "Tagging failed for #{self.class} #{self.id} with tag '#{name}': #{e.message}"
      raise e # Re-raise the error for standard Rails handling
    end
  end
end
