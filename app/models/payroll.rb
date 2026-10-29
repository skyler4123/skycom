# frozen_string_literal: true

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
