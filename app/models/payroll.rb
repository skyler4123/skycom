# frozen_string_literal: true

# Payroll — Atomic purpose: one employee's payroll result for one month.
#
# Why it exists: payroll must be reviewable, approvable, and payable inside
# Skycom without Skycom becoming the payroll calculator or a second source of
# truth for attendance/tax math.
#
# Contract: Skycom is NOT the payroll calculator. It exposes raw input
# (attendance totals, salary/allowance bases) for the company to calculate
# outside Skycom, then stores the finished figures so they can be reviewed,
# approved, paid, and shown in the mobile payroll view.
# How it works: belongs to company/branch/employee and optional
# attendance_month/payroll_config; status is draft/approved/paid; employee +
# company + month is unique. The money columns are the client's submitted
# result snapshot, not values derived by Skycom; only drafts should accept
# edits, while approved/paid rows stay frozen history.
# Legacy: Payrolls::GenerateService still derives provisional amounts from
# attendance and the PAYROLL_* rates. That calculation path is scheduled to
# become a skeleton builder only — see docs/TODO.md.
# Main associations: belongs_to :company, :employee (required), :branch,
# :attendance_month, :payroll_config (optional).
class Payroll < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, { draft: 0, approved: 1, paid: 2 }, prefix: true
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee
  belongs_to :attendance_month, optional: true
  belongs_to :payroll_config, optional: true

  # --- Validations ---
  validates :company_id, presence: true
  validates :employee_id, presence: true
  validates :month, presence: true
  validates :employee_id, uniqueness: { scope: [ :company_id, :month ] }
  validates :base_amount_cents, :allowance_amount_cents, :overtime_amount_cents,
    :gross_amount_cents, :tax_amount_cents, :deduction_amount_cents, :net_amount_cents,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def total_deductions_cents
    tax_amount_cents + deduction_amount_cents
  end
end
