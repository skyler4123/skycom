class ServiceGroupAppointment < ApplicationRecord
  belongs_to :service_group
  belongs_to :appoint_to, polymorphic: true
end
