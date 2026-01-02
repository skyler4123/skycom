class Brand < ApplicationRecord
    include TagConcern

  # --- Associations ---
  has_many :products, dependent: :nullify

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  # Defines the general business category of the brand.
  enum :business_type, {
    manufacturer: 0,
    retailer: 1,
    service_provider: 2,
    technology: 3
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: true
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
end
