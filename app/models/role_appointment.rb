class RoleAppointment < ApplicationRecord
  include Cache::RecordsConcern
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :role
  belongs_to :appoint_to, polymorphic: true, touch: true
  belongs_to :appoint_from, polymorphic: true, optional: true, touch: true
  belongs_to :appoint_for, polymorphic: true, optional: true, touch: true
  belongs_to :appoint_by, polymorphic: true, optional: true, touch: true

  enum :business_type, { owner: 0 }

  validates :appoint_to_type, presence: true
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

    # Only one owner appointment per company (exclude self for updates)
    owner_exists = RoleAppointment.where(
      company_id: company_id,
      appoint_to_type: "Employee",
      business_type: :owner
    ).where.not(id: self.id).exists?

    if owner_exists
      errors.add(:base, "Only one owner role assignment is allowed per company.")
    end

    # Owner role can only be assigned to employees with owner business_type
    if appoint_to_type == "Employee" && appoint_to_id.present?
      employee = Employee.find_by(id: appoint_to_id)
      if employee && employee.business_type.to_s != OWNER_BUSINESS_TYPE
        errors.add(:base, "Owner role can only be assigned to owner employees.")
      end
    end
  end
end
