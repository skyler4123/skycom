class Cart < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :cart_group

  # --- Enums ---
  enum :status, {
    active: 0,
    abandoned: 1,
    converted: 2,
    archived: 3
  }

  enum :business_type, {
    shopping: 0,
    wishlist: 1,
    saved_for_later: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :business_type, presence: true
end