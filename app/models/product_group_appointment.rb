class ProductGroupAppointment < ApplicationRecord
  belongs_to :product_group
  belongs_to :appoint_to, polymorphic: true
end
