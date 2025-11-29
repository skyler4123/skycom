class CustomerGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true

  has_many :customer_group_appointments, dependent: :destroy
  has_many :customers, through: :customer_group_appointments, source: :appoint_to, source_type: "Customer"

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  has_many :service_appointments, dependent: :destroy, as: :appoint_to
  has_many :services, through: :service_appointments

  # --- Enums ---
  enum :status, {
    active: 0,
    inactive: 1,
    archived: 2
  }

  enum :business_type, {
    vip: 0,
    wholesale: 1,
    retail: 2,
    new_customers: 3
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
end