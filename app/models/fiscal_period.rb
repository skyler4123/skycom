# frozen_string_literal: true

# FiscalPeriod — Atomic purpose: one accounting period (month or year) that journal entries are booked into and that can be locked against further posting.
#
# Why it exists: closing the books requires a hard boundary: once a period is locked, no posting may change a report that was already signed off, and 'which period does this entry belong to' must be answerable per company rather than guessed from the date.
# How it works: belongs to a company and holds an explicit date range plus a status (open → locked → closed). A period is derived from the company's fiscal year end, never from the calendar year, because companies with a non-December year end still report in months. Locking is a flag; entries are never moved or deleted.
# Main associations: belongs_to :company, :closed_by_employee (optional); has_many :journal_entries, :depreciation_entries, :budgets.
class FiscalPeriod < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, FISCAL_PERIOD_STATUSES, prefix: true, default: :open

  # --- Associations ---
  belongs_to :company
  belongs_to :closed_by_employee, class_name: "Employee", optional: true
  has_many :journal_entries, dependent: :restrict_with_error
  has_many :depreciation_entries, dependent: :restrict_with_error
  has_many :budgets, dependent: :nullify

  # --- Scopes ---
  scope :for_year, ->(year) { where(fiscal_year: year) }
  scope :open_periods, -> { where(status: :open) }
  scope :chronological, -> { order(:starts_on) }

  # --- Validations ---
  validates :fiscal_year, :period_no, numericality: { only_integer: true, greater_than: 0 }
  validates :period_no, uniqueness: { scope: [ :company_id, :fiscal_year ] }
  validates :starts_on, :ends_on, presence: true
  validate :ends_on_after_starts_on

  # --- Methods ---
  def open?
    status_open?
  end

  def locked_or_closed?
    status_locked? || status_closed?
  end

  def covers?(date)
    starts_on.present? && ends_on.present? && date.to_date.between?(starts_on, ends_on)
  end

  private

  def ends_on_after_starts_on
    return if starts_on.blank? || ends_on.blank? || ends_on >= starts_on

    errors.add(:ends_on, "must be on or after the start date")
  end
end
