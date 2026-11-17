# frozen_string_literal: true

# StockCountLine — Atomic purpose: one counted stock row inside a stocktake: expected quantity, counted quantity, variance.
#
# Why it exists: the variance per item is the finding of a stocktake; keeping expected and counted side by side preserves what the system believed at count time even after the correction lands, which is what shrinkage reporting depends on.
# How it works: expected is snapshotted at count start, counted is filled by the counter, variance is stored rather than computed so the number a report shows never changes later. `storage_location` records where the count happened for bin-level counts.
# Main associations: belongs_to :company, :stock_count, :stock, :storage_location (optional).
class StockCountLine < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :stock_count
  belongs_to :stock
  belongs_to :storage_location, optional: true

  # --- Validations ---
  validates :expected_quantity, numericality: { only_integer: true }
  validates :stock_id, uniqueness: { scope: :stock_count_id }

  # --- Methods ---
  def counted?
    !counted_quantity.nil?
  end

  def recompute_variance!
    return unless counted?

    update!(variance_quantity: counted_quantity.to_i - expected_quantity.to_i)
  end
end
