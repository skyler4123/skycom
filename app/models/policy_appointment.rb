class PolicyAppointment < ApplicationRecord
  belongs_to :policy
  # REASON: When a permission is toggled (created/destroyed), we must update the Role's timestamp so the Role knows its collection of policies has changed.
  # appoint_to can be: role
  belongs_to :appoint_to, polymorphic: true, touch: true
  enum :workflow_status, {
    unactive: 0,
    active: 1
  }
end
