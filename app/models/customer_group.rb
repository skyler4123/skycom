class CustomerGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true

  has_many :customer_group_appointments, dependent: :destroy
  has_many :customers, through: :customer_group_appointments, source: :appoint_to, source_type: "Customer"
  has_many :services, through: :customer_group_appointments, source: :appoint_to, source_type: "Service"

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    vip: 0,
    wholesale: 1,
    retail: 2,
    new_customers: 3
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }

  validates :business_type, presence: true
end
