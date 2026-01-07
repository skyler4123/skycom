class BookingResource < ApplicationRecord
  belongs_to :company_group
  belongs_to :company
  belongs_to :booking_resourceable, polymorphic: true
end
