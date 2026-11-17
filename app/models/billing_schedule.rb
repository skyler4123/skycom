# frozen_string_literal: true

# BillingSchedule — Atomic purpose: the recurrence rule that turns a subscription into invoices on a cadence.
#
# Why it exists: a subscription is not a plan row, it is a promise to bill again; without a stored schedule the next invoice date has to be guessed from the last invoice, which breaks after a skipped or corrected period.
# How it works: one row per subscription group, holding interval, next run date and an idempotent status. The job advances `next_run_on` only after the invoice is created, so a failed run retries the same date instead of skipping a period.
# Main associations: belongs_to :company, :subscription_group; has_many :invoices.
class BillingSchedule < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :interval, BILLING_INTERVALS, prefix: true, default: :monthly

  # --- Associations ---
  belongs_to :company
  belongs_to :subscription_group
  has_many :invoices, dependent: :nullify

  # --- Scopes ---
  scope :due, ->(date = Date.current) { where(status: :active).where(next_run_on: ..date) }
  scope :active, -> { where(status: :active) }

  # --- Validations ---
  validates :interval_count, numericality: { only_integer: true, greater_than: 0 }
  validates :next_run_on, presence: true

  # --- Methods ---
  def advance!
    update!(last_run_on: next_run_on, next_run_on: next_run_on + interval_count.send(interval))
  end
end
