class ProductGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  has_many :product_group_appointments, dependent: :destroy
  has_many :products, through: :product_group_appointments, source: :appoint_to, source_type: "Product"

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    category: 0,
    collection: 1,
    line: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
end
