class PolicyRoleAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :workflow_status, { inactive: 0, active: 1 }
  enum :business_type, { owner: 0 }
  belongs_to :company
  belongs_to :policy
  belongs_to :role, touch: true

  validate :only_one_owner_appointment_per_company, on: :create

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

  def only_one_owner_appointment_per_company
    return unless business_type.to_s == OWNER_BUSINESS_TYPE && company_id.present?

    owner_exists = PolicyRoleAppointment.where(
      company_id: company_id,
      business_type: :owner
    ).where.not(id: self.id).exists?

    if owner_exists
      errors.add(:base, "Only one owner policy assignment is allowed per company.")
    end
  end
end
