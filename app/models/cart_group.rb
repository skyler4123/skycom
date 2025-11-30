class CartGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  # has_many :cart_group_appointments, dependent: :destroy # This can be added later

  # --- Enums ---
  enum :status, {
    active: 0,
    inactive: 1,
    archived: 2
  }

  enum :business_type, {
    abandoned: 0,
    active_carts: 1,
    wishlists: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
end