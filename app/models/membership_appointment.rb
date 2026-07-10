# app/models/membership_appointment.rb
class MembershipAppointment < ApplicationRecord
  attribute :metadata, :jsonb, array: true, default: []

  belongs_to :membership
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true   # The Customer or User
  belongs_to :appoint_for, polymorphic: true, optional: true # The Company or Store
  belongs_to :appoint_by, polymorphic: true, optional: true  # Who assigned this

  enum :lifecycle_status, { active: 0, archived: 1 }, prefix: true
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true

  # Context of this specific appointment
  enum :business_type, { primary: 0, loyalty: 1, subscription: 2, segment: 3 }
end
