class RoleAppointment < ApplicationRecord
  include CompanyFromAssociation

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :role
  belongs_to :appoint_to, polymorphic: true, touch: true
  belongs_to :appoint_from, polymorphic: true, optional: true, touch: true
  belongs_to :appoint_for, polymorphic: true, optional: true, touch: true
  belongs_to :appoint_by, polymorphic: true, optional: true, touch: true

  enum :business_type, { owner: 0 }

  before_update :prevent_modification_if_owner
  before_destroy :prevent_modification_if_owner

  private

  def prevent_modification_if_owner
    return unless business_type == "owner"
    raise ActiveRecord::ReadOnlyRecord, "Owner records cannot be modified."
  end
end
