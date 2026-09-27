class EmployeeGroupRoleAppointment < ApplicationRecord
  # Role assignment — atomic row granting one Role to its holder record.
  #
  # Why it exists: roles collect ABAC policies (see docs/ABAC.md); this table is
  # the many-to-many grant between a role and exactly one holder type.
  # How to use: prefer `record.attach_role(name)` (see RoleConcern); read via
  # the roles has_many/through on the holder.
  # How it works: Role sorts last alphabetically, so tables are always
  # <Holder>RoleAppointment with a concrete holder FK. company_id derives from
  # the holder via SetDefaultCompanyConcern. Rows with business_type :owner are
  # immutable and clear the permissions cache on change.
  include Cache::RecordsConcern
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :business_type, { owner: 0 }
  belongs_to :company
  belongs_to :employee_group, touch: true
  belongs_to :role

  validate :only_one_owner_appointment_per_company, on: :create

  after_create :clear_company_permissions_cache
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

    owner_exists = EmployeeGroupRoleAppointment.where(
      company_id: company_id,
      business_type: :owner
    ).where.not(id: self.id).exists?

    if owner_exists
      errors.add(:base, "Only one owner role assignment is allowed per company.")
    end
  end
end
