class TagAppointment < ApplicationRecord
  belongs_to :tag
  belongs_to :appoint_to, polymorphic: true
end
