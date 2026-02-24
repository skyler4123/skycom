class BookingPeriod < ApplicationRecord
  belongs_to :booking_resource
  belongs_to :period
end
