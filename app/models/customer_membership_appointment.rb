class CustomerMembershipAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, { active: 0, archived: 1 }, prefix: true
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true
  enum :business_type, { primary: 0, loyalty: 1, subscription: 2, segment: 3 }
  belongs_to :company
  belongs_to :customer
  belongs_to :membership
end
