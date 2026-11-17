# frozen_string_literal: true

# StorageLocation — Atomic purpose: a physical place inside a warehouse (zone, aisle, rack, bin) that stock movements can point at.
#
# Why it exists: a warehouse that only knows 'we have 40' cannot be picked from. Exact locations are what make put-away, pick lists and stocktakes executable, and they must be a tree because a bin is inside a rack inside an aisle inside a zone.
# How it works: self-referencing tree with a company-unique code and a pick_sequence so warehouse walks stay in a sane order. Quantity is deliberately NOT stored here — stock_transactions carry the location and the quantity is derived, preserving the single write path in docs/STOCK.md.
# Main associations: belongs_to :company, :warehouse, :parent (optional); has_many :children, :stock_transactions, :stock_serials, :pick_tasks.
class StorageLocation < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :location_type, STORAGE_LOCATION_TYPES, prefix: true, default: :bin

  # --- Associations ---
  belongs_to :company
  belongs_to :warehouse
  belongs_to :parent, class_name: "StorageLocation", optional: true, inverse_of: :children
  has_many :children, class_name: "StorageLocation", foreign_key: :parent_id, inverse_of: :parent, dependent: :restrict_with_error
  has_many :stock_serials, dependent: :nullify
  has_many :pick_tasks, dependent: :nullify

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }
  scope :pick_order, -> { order(:pick_sequence, :code) }

  # --- Validations ---
  validates :code, presence: true, length: { maximum: 32 }, uniqueness: { scope: :warehouse_id }
  validate :parent_not_self

  private

  def parent_not_self
    return if parent_id.blank? || parent_id != id

    errors.add(:parent, "cannot be itself")
  end
end
