class BookingResource < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :booking_resourceable, polymorphic: true
end
