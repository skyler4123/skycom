class BookingResource < ApplicationRecord
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :booking_resourceable, polymorphic: true
end
