class PaymentMethod < ApplicationRecord
  # --- Associations ---
  # This model is intended to be global, so it does not belong to a company.
  # has_many :payments # This association can be added if you refactor the Payment model

  # --- Enums ---
  enum :status, {
    active: 0,
    inactive: 1,
    restricted: 2
  }

  enum :business_type, {
    online: 0,
    offline: 1,
    global: 2
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: true
  validates :status, presence: true
  validates :business_type, presence: true
end