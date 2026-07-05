# app/models/reservation_appointment.rb
class ReservationAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :metadata, :jsonb, default: {}

  belongs_to :company
  belongs_to :reservation

  # Polymorphic associations matching your existing logic
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true

  enum :lifecycle_status, { active: 0, archived: 1 }
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }
end
