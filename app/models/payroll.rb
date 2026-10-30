# frozen_string_literal: true

# Payroll — Atomic purpose: one employee's payroll result for one month.
#
# Why it exists: stores the approved/paid salary outcome per employee/month and
# links it to the attendance rollup and payroll configuration used to compute it.
# How it works: belongs to company/branch/employee and optional
# attendance_month/payroll_config; status is draft/approved/paid; employee +
# company + month is unique.
# Main associations: belongs_to :company, :employee (required), :branch,
# :attendance_month, :payroll_config (optional).
class Payroll < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, { draft: 0, approved: 1, paid: 2 }, prefix: true

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
end
