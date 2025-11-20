class Booking < ApplicationRecord
  belongs_to :company
  belongs_to :appoint_from, polymorphic: true
  belongs_to :appoint_to, polymorphic: true
end
