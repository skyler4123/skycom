# app/models/price_appointment.rb
class PriceAppointment < ApplicationRecord
  # The "What" (Immutable Facts)
  belongs_to :price
  belongs_to :period, optional: true

  # The "To Whom" (The Resource)
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true

  # The "Context" (Business Logic)
  enum :business_type, { base: 0, sale: 1, wholesale: 2, msrp: 3 }
  enum :lifecycle_status, { active: 0, archived: 1 }
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }
end
