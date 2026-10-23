class EmployeeSubprofile < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  include Discard::Model
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    general: 0,
    special: 1
  }

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee
  belongs_to :employee_profile
  belongs_to :category
  belongs_to :property_mapping

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :employee_profile_id }, length: { maximum: 255 }
  validates :code, uniqueness: { scope: :company_id }, allow_blank: true
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
  validate :employee_matches_profile_employee

  private

  def employee_matches_profile_employee
    return if employee_id.blank? || employee_profile.nil?

    if employee_id != employee_profile.employee_id
      errors.add(:employee, "must match profile's employee")
    end
    if company_id != employee_profile.company_id
      errors.add(:company, "must match profile's company")
    end
  end
end
