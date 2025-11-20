class CustomerGroupAppointment < ApplicationRecord
  belongs_to :customer_group
  belongs_to :appoint_to, polymorphic: true
end
