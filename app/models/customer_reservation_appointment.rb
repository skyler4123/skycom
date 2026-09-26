class CustomerReservationAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, { active: 0, archived: 1, deleted: 2 }
  enum :workflow_status, { draft: 0, confirmed: 1, checked_in: 2, completed: 3, cancelled: 4 }
  enum :business_type, { primary: 0, dining: 1, maintenance: 2 }
  belongs_to :company
  belongs_to :customer
  belongs_to :reservation
end
