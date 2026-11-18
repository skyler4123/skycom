# frozen_string_literal: true

# ProductionOrder — Atomic purpose: one instruction to manufacture a quantity of one product, from a specific BOM version.
#
# Why it exists: shop-floor execution, material issue and production cost all attach to a work order; without it there is nothing to start, pause, consume material into, or compare against standard cost.
# How it works: references the product, the BOM it was planned from and the warehouse that will receive output. Materials and operations are child rows so consumption can be logged per line. Status follows the shared workflow enum, and completion is what triggers the stock receipt.
# Main associations: belongs_to :company, :product, :bill_of_material (optional), :warehouse; has_many :production_order_materials, :production_order_operations.
class ProductionOrder < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  belongs_to :product
  belongs_to :bill_of_material, optional: true
  belongs_to :warehouse
  has_many :production_order_materials, dependent: :destroy
  has_many :production_order_operations, dependent: :destroy

  # --- Scopes ---
  scope :open_orders, -> { where(status: [ :pending, :confirmed, :in_progress ]) }
  scope :scheduled_between, ->(from, to) { where(scheduled_start_at: from..to) }

  # --- Validations ---
  validates :quantity, numericality: { greater_than: 0 }
end
