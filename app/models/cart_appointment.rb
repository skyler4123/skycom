class CartAppointment < ApplicationRecord
  belongs_to :cart
  belongs_to :appoint_from, polymorphic: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true
end
