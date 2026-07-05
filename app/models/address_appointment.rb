class AddressAppointment < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :metadata, :jsonb, default: {}

  belongs_to :address
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true

  enum :lifecycle_status, { active: 0, archived: 1 }, prefix: true
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true
  enum :business_type, { office: 0, home: 1, billing: 2, shipping: 3 }
end
