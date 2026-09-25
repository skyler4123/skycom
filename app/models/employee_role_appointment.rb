class EmployeeRoleAppointment < ApplicationRecord
  include Cache::RecordsConcern
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :business_type, { owner: 0 }
  belongs_to :company
  belongs_to :employee, touch: true
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

    owner_exists = EmployeeRoleAppointment.where(
      company_id: company_id,
      business_type: :owner
    ).where.not(id: self.id).exists?

    if owner_exists
      errors.add(:base, "Only one owner role assignment is allowed per company.")
    end

    # Owner role can only be assigned to employees with owner business_type
    if employee_id.present?
      employee = Employee.find_by(id: employee_id)
      if employee && employee.business_type.to_s != OWNER_BUSINESS_TYPE
        errors.add(:base, "Owner role can only be assigned to owner employees.")
      end
    end
  end
end
