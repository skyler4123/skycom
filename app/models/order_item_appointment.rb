class OrderItemAppointment < ApplicationRecord
  belongs_to :order
  belongs_to :appoint_to, polymorphic: true

  # --- Enums ---
  enum :status, { 
    fulfilled: 0, 
    pending: 1, 
    backordered: 2 
  }

  # --- Validations ---
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # --- Callbacks ---
  before_validation -> { self.total_price = quantity * unit_price if quantity.present? && unit_price.present? }
end
