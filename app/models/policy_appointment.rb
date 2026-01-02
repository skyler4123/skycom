class PolicyAppointment < ApplicationRecord
  belongs_to :policy
  belongs_to :appoint_to, polymorphic: true, touch: true
end
