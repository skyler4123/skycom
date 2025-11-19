class ProductBrand < ApplicationRecord
  # --- Associations ---
  # has_many :products, dependent: :destroy

  # --- Enums ---
  enum :status, {
    active: 0,
    pending_review: 1,
    discontinued: 2
  }

  enum :business_type, {
    luxury: 0,
    mid_range: 1,
    economy: 2
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
end