class PolicyAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :metadata, :jsonb, array: true, default: []

  belongs_to :company
  belongs_to :policy
  belongs_to :appoint_to, polymorphic: true, touch: true
  enum :workflow_status, {
    inactive: 0,
    active: 1
  }

  enum :business_type, { owner: 0 }

  after_create :clear_company_permissions_cache
  after_update :clear_company_permissions_cache, if: :workflow_status_changed?
  before_update :prevent_modification_if_owner
  before_destroy :prevent_modification_if_owner

  private

  def clear_company_permissions_cache
    company&.clear_permissions_cache
  end

  def prevent_modification_if_owner
    return unless business_type == OWNER_BUSINESS_TYPE
    raise ActiveRecord::ReadOnlyRecord, "Owner records cannot be modified."
  end
end
