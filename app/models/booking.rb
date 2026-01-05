class Booking < ApplicationRecord
  belongs_to :company_group
  belongs_to :company
  belongs_to :booking_resource
  belongs_to :price
  belongs_to :appoint_from, polymorphic: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true
  belongs_to :appoint_by, polymorphic: true
  belongs_to :price
end
