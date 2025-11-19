class Customer < ApplicationRecord
  # --- Associations ---
  belongs_to :company, optional: true

  has_many :orders, dependent: :destroy
  # --- Enums ---
  enum :status, {
    active: 0,
    prospect: 1,
    inactive: 2
  }

  enum :business_type, {
    individual: 0,
    small_business: 1,
    enterprise: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :business_type, presence: true
end