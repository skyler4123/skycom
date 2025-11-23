class Order < ApplicationRecord
  # --- Associations ---
  belongs_to :company

  has_many :invoices, dependent: :destroy
  has_many :order_item_appointments, dependent: :destroy
  has_many :products, through: :order_item_appointments, source: :appoint_to, source_type: "Product"
  has_many :services, through: :order_item_appointments, source: :appoint_to, source_type: "Service"


  # --- Enums ---
  enum :status, {
    pending: 0,
    processing: 1,
    shipped: 2,
    completed: 3,
    cancelled: 4
  }

  enum :business_type, {
    online: 0,
    in_store: 1,
    phone: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :currency, presence: true
  validates :status, presence: true
  validates :business_type, presence: true
end