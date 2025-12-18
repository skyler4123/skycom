class Service < ApplicationRecord
  belongs_to :company_group
  belongs_to :company, optional: true

  has_many :order_appointments, as: :appoint_to, dependent: :destroy
  has_many :orders, through: :order_appointments

  has_many :service_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :service_groups, through: :service_group_appointments

  # has_many :service_appointments, dependent: :destroy
  # has_many :customer_groups, through: :service_appointments, source: :appoint_to, source_type: 'CustomerGroup'
  has_many :customer_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :customer_groups, through: :customer_group_appointments

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  has_many :service_appointments, dependent: :destroy
  has_many :customers, through: :service_appointments, source: :appoint_to, source_type: "Customer"
  has_many :employees, through: :service_appointments, source: :appoint_to, source_type: "Employee"

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    b2b: 0,
    b2c: 1
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :status, presence: true
  validates :business_type, presence: true
end
