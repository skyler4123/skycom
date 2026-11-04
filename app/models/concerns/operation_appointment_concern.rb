# frozen_string_literal: true

# OperationAppointmentConcern — Atomic purpose: gives a location model the
# company's full operation catalog as atomic operation-appointment rows.
#
# Why it exists: every new branch or warehouse must be able to launch every
# operation scoped to it. The behavior is identical for every location model,
# so it lives here instead of being repeated in each model.
# How it works: after_create calls Seed::OperationService.ensure_appointments_for!
# with the appointment class, operation scope, and foreign key declared by the
# includer. The service is idempotent.
# Main associations: the includer must belong_to :company and must call
# operation_appointments_for with its atomic appointment model.
module OperationAppointmentConcern
  extend ActiveSupport::Concern

  included do
    after_create :ensure_operation_appointments
  end

  class_methods do
    def operation_appointments_for(appointment_class, scope:, foreign_key:)
      class_attribute :operation_appointment_class, instance_writer: false
      class_attribute :operation_appointment_scope_name, instance_writer: false
      class_attribute :operation_appointment_foreign_key, instance_writer: false

      self.operation_appointment_class = appointment_class
      self.operation_appointment_scope_name = scope
      self.operation_appointment_foreign_key = foreign_key
    end
  end

  private

  def ensure_operation_appointments
    return unless company
    return unless self.class.operation_appointment_class

    Seed::OperationService.ensure_appointments_for!(
      location: self,
      appointment_class: self.class.operation_appointment_class,
      operation_scope: self.class.operation_appointment_scope_name,
      foreign_key: self.class.operation_appointment_foreign_key
    )
  end
end
