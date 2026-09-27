# app/models/employee.rb

class Employee < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include AddressConcern
  include AvatarConcern
  include Employee::ImageConcern
  include RoleConcern
  include Employee::PermissionConcern
  include TagConcern
  include Discard::Model
  include Cache::RecordsConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # has_paper_trail

  # --- Enums ---
  enum :business_type, {
    owner: 0,
    full_time: 1,
    part_time: 2,
    contractor: 3,
    intern: 4
  }
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :user, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_role_appointments, dependent: :destroy
  has_many :roles, through: :employee_role_appointments
  has_many :scheduled_shifts, dependent: :destroy
  has_many :attendance_logs, dependent: :destroy
  has_many :attendance_days, dependent: :destroy
  has_many :attendance_months, dependent: :destroy

  has_many :employee_employee_group_appointments, dependent: :destroy
  has_many :employee_groups, through: :employee_employee_group_appointments

  has_many :department_employee_appointments, dependent: :destroy
  has_many :departments, through: :department_employee_appointments

  has_many :employee_service_appointments, dependent: :destroy
  has_many :services, through: :employee_service_appointments

  has_many :customer_employee_appointments, dependent: :destroy
  has_many :customers, through: :customer_employee_appointments

  has_many :article_employee_appointments, dependent: :destroy
  has_many :articles, through: :article_employee_appointments

  has_many :article_group_employee_appointments, dependent: :destroy
  has_many :article_groups, through: :article_group_employee_appointments

  has_many :document_employee_appointments, dependent: :destroy
  has_many :documents, through: :document_employee_appointments

  has_many :document_group_employee_appointments, dependent: :destroy
  has_many :document_groups, through: :document_group_employee_appointments

  has_many :employee_event_appointments, dependent: :destroy
  has_many :events, through: :employee_event_appointments

  has_many :employee_event_group_appointments, dependent: :destroy
  has_many :event_groups, through: :employee_event_group_appointments

  has_many :employee_exam_appointments, dependent: :destroy
  has_many :exams, through: :employee_exam_appointments

  has_many :employee_facility_appointments, dependent: :destroy
  has_many :facilities, through: :employee_facility_appointments

  has_many :employee_notification_appointments, dependent: :destroy
  has_many :notifications, through: :employee_notification_appointments

  has_many :employee_notification_group_appointments, dependent: :destroy
  has_many :notification_groups, through: :employee_notification_group_appointments

  has_many :employee_order_group_appointments, dependent: :destroy
  has_many :order_groups, through: :employee_order_group_appointments

  has_many :employee_product_appointments, dependent: :destroy
  has_many :products, through: :employee_product_appointments

  has_many :employee_project_appointments, dependent: :destroy
  has_many :projects, through: :employee_project_appointments

  has_many :employee_project_group_appointments, dependent: :destroy
  has_many :project_groups, through: :employee_project_group_appointments

  has_many :employee_setting_appointments, dependent: :destroy
  has_many :settings, through: :employee_setting_appointments

  has_many :employee_setting_group_appointments, dependent: :destroy
  has_many :setting_groups, through: :employee_setting_group_appointments

  has_many :employee_task_appointments, dependent: :destroy
  has_many :tasks, through: :employee_task_appointments

  has_many :employee_task_group_appointments, dependent: :destroy
  has_many :task_groups, through: :employee_task_group_appointments

  has_many :employee_employee_appointments, dependent: :destroy
  has_many :related_employees, through: :employee_employee_appointments
  has_many :inverse_employee_employee_appointments, class_name: "EmployeeEmployeeAppointment",
           foreign_key: :related_employee_id, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :business_type, presence: true
  validate :only_one_owner_per_company, on: :create

  before_discard :prevent_discard_if_owner
  before_destroy :prevent_destroy_if_owner

  private

  def only_one_owner_per_company
    return unless business_type.to_s == OWNER_BUSINESS_TYPE && company_id.present?

    # Only one owner employee per company
    # Allow if this employee is updating their own record (same id)
    return if persisted? && self.id == Employee.find_by(company_id: company_id, business_type: OWNER_BUSINESS_TYPE)&.id

    owner_exists = Employee.where(company_id: company_id, business_type: OWNER_BUSINESS_TYPE)
      .where.not(id: self.id)
      .exists?

    if owner_exists
      errors.add(:base, "Only one owner employee is allowed per company.")
    end
  end

  def prevent_discard_if_owner
    return unless business_type.to_s == OWNER_BUSINESS_TYPE
    errors.add(:base, "Owner employee cannot be discarded.")
    throw(:abort)
  end

  def prevent_destroy_if_owner
    return unless business_type.to_s == OWNER_BUSINESS_TYPE
    errors.add(:base, "Owner employee cannot be destroyed.")
    throw(:abort)
  end
end
