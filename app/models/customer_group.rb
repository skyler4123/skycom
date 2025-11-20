class CustomerGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  has_many :customer_group_appointments, dependent: :destroy

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