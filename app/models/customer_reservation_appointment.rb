class CustomerReservationAppointment < ApplicationRecord
  # Customer entitlement link — atomic row attaching a Membership/Reservation.
  #
  # Why it exists: a customer can hold concurrent entitlements per business_type
  # (e.g. dining booking AND maintenance visit); this table versions them.
  # How to use: call `customer.attach_reservation(code, business_type:)`
  # (see ReservationConcern); read via `customer.reservation` / `reservation_of_type`.
  # How it works: attaching archives only the active row of the SAME
  # business_type, leaving other tracks untouched. company_id derives from the
  # customer via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, { active: 0, archived: 1, deleted: 2 }
  enum :workflow_status, { draft: 0, confirmed: 1, checked_in: 2, completed: 3, cancelled: 4 }
  enum :business_type, { primary: 0, dining: 1, maintenance: 2 }
  belongs_to :company
  belongs_to :customer
  belongs_to :reservation
end
