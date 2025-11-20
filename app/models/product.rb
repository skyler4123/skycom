class Product < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :product_brand, optional: true

  has_many :order_item_appointments, as: :appoint_to, dependent: :destroy
  has_many :orders, through: :order_item_appointments

  # --- Enums ---
  enum :status, {
    draft: 0,
    available: 1,
    discontinued: 2
  }

  enum :business_type, {
    physical: 0,
    digital: 1,
    service_based: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :business_type, presence: true
end