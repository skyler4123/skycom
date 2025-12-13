class Brand < ApplicationRecord
  # --- Associations ---
  has_many :products, dependent: :nullify

  # --- Enums ---
  # Defines the possible statuses for a brand.
  enum :status, {
    active: 0,
    inactive: 1,
    archived: 2
  }

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
  validates :status, presence: true
  validates :business_type, presence: true
end
