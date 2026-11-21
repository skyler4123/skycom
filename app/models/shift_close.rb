# frozen_string_literal: true

# ShiftClose — one branch's close-of-shift record for one business date.
#
# Why it exists: the store manager must store the counted cash, the expected
# cash, the variance and the report figures so a later reload or print shows the
# same numbers. Recomputing from live orders would rewrite a closed day.
# How it works: belongs to company/branch, optional closing employee; stores
# sales/tender/cash figures plus staff and shelf snapshots. The
# StoreManager::ShiftCloseService computes the figures; this model only guards
# the stored shape and the one-close-per-branch/day rule.
# Main associations: belongs_to :company, :branch (required), :closed_by
# (Employee, optional).
class ShiftClose < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :branch
  belongs_to :closed_by, class_name: "Employee", optional: true

  # --- Validations ---
  validates :business_date, presence: true
  validates :business_date, uniqueness: { scope: :branch_id }
  validates :opening_float_cents, :counted_cash_cents, :expected_cash_cents,
    :cash_sales_cents, :qr_sales_cents, :other_sales_cents,
    :cash_received_cents, :change_cents, :discounts_cents, :tax_cents,
    :gross_sales_cents, :orders_count, :open_handovers_count, :shelf_short_count,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :variance_cents, numericality: { only_integer: true }
  validate :note_explains_variance

  private

  def note_explains_variance
    return if variance_cents.to_i.zero? || note.present?

    errors.add(:note, "is required when the variance is not zero")
  end
end
