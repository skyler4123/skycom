class FacilityGroupAppointment < ApplicationRecord
  belongs_to :facility_group
  belongs_to :appoint_to, polymorphic: true
end
