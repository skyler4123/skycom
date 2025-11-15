class RoleAppointment < ApplicationRecord
  belongs_to :role
  belongs_to :appoint_to, polymorphic: true
end
