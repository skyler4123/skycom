class PeriodAppointment < ApplicationRecord
  belongs_to :period
  belongs_to :appoint_to, polymorphic: true
end
