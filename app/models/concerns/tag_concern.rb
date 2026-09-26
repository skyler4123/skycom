# Provides instance methods for attaching and managing Tags on a resource
# via its atomic pairwise appointment table (AWS-style tagging).
#
# Each includer resolves its own table by alphabetical pair order, e.g.
# Employee => EmployeeTagAppointment, Product => ProductTagAppointment,
# Task => TagTaskAppointment (Tag sorts before Task/TaskGroup/Transaction/Warehouse).
module TagConcern
  extend ActiveSupport::Concern

  class << self
    # Atomic appointment class name for a taggable record class name.
    def appointment_class_name_for(record_class_name)
      pair = [ record_class_name, "Tag" ].sort
      "#{pair[0]}#{pair[1]}Appointment"
    end

    # Atomic appointment class for a taggable record class.
    def tag_appointment_class_for(record_class)
      name = record_class.is_a?(Class) ? record_class.name : record_class.to_s
      appointment_class_name_for(name).constantize
    end

    # Association name on the taggable record, e.g. :employee_tag_appointments.
    def tag_appointment_association_for(record_class)
      name = record_class.is_a?(Class) ? record_class.name : record_class.to_s
      pair = [ name, "Tag" ].sort
      "#{pair.map { |part| part.underscore }.join('_')}_appointments".to_sym
    end
  end

  class_methods do
    def tag_appointment_class_for(record_class)
      TagConcern.tag_appointment_class_for(record_class)
    end
  end

  included do
    tag_assoc = TagConcern.tag_appointment_association_for(name)
    tag_appointment_class_name = TagConcern.appointment_class_name_for(name)

    has_many tag_assoc,
      class_name: tag_appointment_class_name,
      foreign_key: "#{name.underscore}_id",
      dependent: :destroy
    has_many :tags, through: tag_assoc

    # Backward-compatible reader routing to the concrete association.
    define_method(:tag_appointments) { public_send(tag_assoc) }

    # Assigns a new tag or updates the value of an existing tag key on the resource.
    # This method is transactional to ensure atomic creation/update.
    #
    # @param key [String] The key (key) of the tag.
    # @param value [String, nil] The value to assign to the tag.
    # @param description [String, nil] An optional description for the appointment.
    # @return [ActiveRecord::Base] The created or updated atomic tag appointment.
    def attach_tag(key:, value: nil, description: nil)
      # Ensure the object has a 'company' association for proper tag scoping
      raise "Model must belong to a company group to attach a tag." unless respond_to?(:company) && company

      assoc = TagConcern.tag_appointment_association_for(self.class)

      ApplicationRecord.transaction do
        # 1. Find or create the Tag (the Key) scoped to the company
        tag = company.tags.find_or_create_by!(key: key)
        # 2. Sync value on Tag (used by ABAC evaluate_tag_conditions via target.tags)
        tag.update!(value: value) if tag.value != value
        # 3. Find or initialize the atomic appointment (the Assignment).
        # This handles the uniqueness constraint: only one Appointment per (Tag + Resource).
        appointment = public_send(assoc).find_or_initialize_by(tag: tag)

        # 4. Update the fields
        appointment.value = value
        appointment.description = description
        appointment.company = company

        # 5. Save the appointment (creates if new, updates if existing)
        appointment.save!

        appointment # Return the resulting appointment
      end
    rescue ActiveRecord::RecordInvalid => e
      # Provides context for which record failed validation
      Rails.logger.error "Tagging failed for #{self.class} #{self.id} with tag '#{key}': #{e.message}"
      raise e # Re-raise the error for standard Rails handling
    end
  end
end
