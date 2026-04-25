class PolicyAppointment < ApplicationRecord
  include CompanyFromAssociation

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :policy
  belongs_to :appoint_to, polymorphic: true, touch: true
  enum :workflow_status, {
    inactive: 0,
    active: 1
  }

  enum :business_type, { owner: 0 }

  before_update :prevent_modification_if_owner
  before_destroy :prevent_modification_if_owner

  private

  def prevent_modification_if_owner
    return unless business_type == "owner"
    raise ActiveRecord::ReadOnlyRecord, "Owner records cannot be modified."
  end
end
