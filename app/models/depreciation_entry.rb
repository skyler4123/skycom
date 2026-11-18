# frozen_string_literal: true

# DepreciationEntry — Atomic purpose: one month's depreciation charge for one asset, linked to the journal entry that posted it.
#
# Why it exists: the schedule must be replayable: re-running a period, correcting a life, or auditing a closed year all need the per-period charge as its own immutable row, not a computed column that changes when the method changes.
# How it works: created once per (asset, fiscal period) — the unique index makes re-runs idempotent. `accumulated_cents` is the running total after this charge, stored so a report does not have to sum every prior row. Immutable: corrections are new rows plus a reversing entry.
# Main associations: belongs_to :company, :fixed_asset, :fiscal_period, :journal_entry (optional).
class DepreciationEntry < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :fixed_asset
  belongs_to :fiscal_period
  belongs_to :journal_entry, optional: true

  # --- Validations ---
  validates :amount_cents, :accumulated_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :fiscal_period_id, uniqueness: { scope: :fixed_asset_id }
end
