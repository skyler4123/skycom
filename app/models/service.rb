class Service < ApplicationRecord
  belongs_to :company

  has_many :order_item_appointments, as: :appoint_to, dependent: :destroy
  has_many :orders, through: :order_item_appointments

  # --- Enums ---
  enum :status, { 
    active: 0, 
    pending: 1, 
    archived: 2 
  }

  enum :business_type, { 
    b2b: 0, 
    b2c: 1 
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :status, presence: true
  validates :business_type, presence: true
end