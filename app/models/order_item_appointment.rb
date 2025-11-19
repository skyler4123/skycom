class OrderItemAppointment < ApplicationRecord
  belongs_to :order
  belongs_to :appoint_to, polymorphic: true
end
