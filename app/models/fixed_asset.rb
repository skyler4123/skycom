# frozen_string_literal: true

# FixedAsset — Atomic purpose: one capitalised asset (machine, vehicle, fit-out) tracked from acquisition to disposal.
#
# Why it exists: assets are not expenses: their cost must be spread over the periods that benefit from them, or profit is understated on purchase and overstated afterwards. Keeping acquisition cost, salvage, life and method on one row is what makes the depreciation schedule and the disposal gain/loss computable.
# How it works: DepreciationEntries hold the monthly amounts and point at the journal entry that posted them; this row only owns the terms. `useful_life_months` is months rather than years so partial-year and mid-month conventions stay expressible. Disposal sets `disposed_on`; a disposed asset is never destroyed because its history stays in the ledger.
# Main associations: belongs_to :company, :branch (optional), :ledger_account (optional), :cost_center (optional); has_many :depreciation_entries.
class FixedAsset < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :depreciation_method, DEPRECIATION_METHODS, prefix: true, default: :straight_line

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :ledger_account, optional: true
  belongs_to :cost_center, optional: true
  has_many :depreciation_entries, dependent: :restrict_with_error

  # --- Scopes ---
  scope :active, -> { where(disposed_on: nil) }
  scope :ordered, -> { order(:code) }

  # --- Validations ---
  validates :code, presence: true, length: { maximum: 32 }, uniqueness: { scope: :company_id }
  validates :name, presence: true, length: { maximum: 255 }
  validates :acquired_on, presence: true
  validates :useful_life_months, numericality: { only_integer: true, greater_than: 0 }
  validates :cost_cents, :salvage_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # --- Methods ---
  def depreciable_cents
    [ cost_cents.to_i - salvage_cents.to_i, 0 ].max
  end

  def monthly_depreciation_cents
    return 0 if useful_life_months.to_i.zero?

    (depreciable_cents.to_f / useful_life_months.to_i).round
  end

  def disposed?
    disposed_on.present?
  end
end
