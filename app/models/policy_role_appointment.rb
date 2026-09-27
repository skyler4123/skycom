class PolicyRoleAppointment < ApplicationRecord
  # Role assignment — atomic row granting one Policy to one Role.
  #
  # Why it exists: roles collect ABAC policies (see docs/ABAC.md); this table is
  # the many-to-many grant between a policy and the role that carries it.
  # How to use: managed via the Permissions dashboard (assign/revoke policy to
  # role); read via the policies/roles has_many/through on either side.
  # How it works: concrete FKs to company/policy/role (role touched on change so
  # employee caches invalidate). company_id derives via SetDefaultCompanyConcern.
  # Rows with business_type :owner are immutable and clear the permissions cache.
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
