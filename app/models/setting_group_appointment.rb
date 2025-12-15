class SettingGroupAppointment < ApplicationRecord
  belongs_to :setting_group
  belongs_to :appoint_from, polymorphic: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true
  belongs_to :appoint_by, polymorphic: true
end
