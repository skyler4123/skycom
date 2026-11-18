# frozen_string_literal: true

# CommissionEntry — Atomic purpose: the commission earned by one employee from one order or invoice, with the plan and amount used.
#
# Why it exists: commission is a liability the moment the sale is booked, but it is paid through payroll weeks later; a row per earning is what lets payroll pick it up, lets a manager explain a payslip, and lets a reversal claw it back.
# How it works: points at the plan and the source document, stores `base_cents` (what it was calculated on) and `amount_cents` (what is owed). `payroll_id` is set once payroll consumes it, so an entry is never paid twice. Status tracks pending/approved/paid/cancelled.
# Main associations: belongs_to :company, :employee, :commission_plan, :order (optional), :invoice (optional), :payroll (optional).
class CommissionEntry < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, COMMISSION_ENTRY_STATUSES, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :employee
  belongs_to :commission_plan
  belongs_to :order, optional: true
  belongs_to :invoice, optional: true
  belongs_to :payroll, optional: true

  # --- Scopes ---
  scope :unpaid, -> { where(status: [ :pending, :approved ]) }
  scope :paid, -> { where(status: :paid) }

  # --- Validations ---
  validates :base_cents, :amount_cents, numericality: { only_integer: true }
end
