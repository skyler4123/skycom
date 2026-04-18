class RoleAppointment < ApplicationRecord
  include CompanyFromAssociation

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :role
  belongs_to :appoint_to, polymorphic: true, touch: true
  belongs_to :appoint_from, polymorphic: true, optional: true, touch: true
  belongs_to :appoint_for, polymorphic: true, optional: true, touch: true
  belongs_to :appoint_by, polymorphic: true, optional: true, touch: true
end
