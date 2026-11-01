# frozen_string_literal: true

# AttendanceBalance — Atomic purpose: one employee's paid-leave entitlement for
# one year.
#
# Why it exists: leave entitlement is annual and per employee; one row per
# (employee, year) makes remaining-day math deterministic and prevents
# duplicate balances.
# How it works: belongs to company/employee. `entitled_days` is the granted
# allowance; approved/pending/remaining days are derived from paid
# AttendanceLeave rows in the same year. `.for` returns an unsaved zero balance
# when no row exists yet.
# Main associations: belongs_to :company, :employee (required).
class AttendanceBalance < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :employee

  # --- Validations ---
  validates :year, presence: true
  validates :entitled_days, numericality: { greater_than_or_equal_to: 0 }
  validates :employee_id, uniqueness: { scope: :year }
  validate :employee_belongs_to_company

  def self.for(employee:, year: Date.current.year)
    find_by(employee: employee, year: year) ||
      new(employee: employee, company: employee.company, year: year, entitled_days: 0)
  end

  def approved_days
    paid_requests.where(status: :approved).sum(:days)
  end

  def pending_days
    paid_requests.where(status: :pending).sum(:days)
  end

  def remaining_days
    [ entitled_days - approved_days, 0 ].max
  end

  private

  def employee_belongs_to_company
    return if employee.blank? || company_id.blank?
    return if employee.company_id == company_id

    errors.add(:employee, "must belong to the same company")
  end

  def paid_requests
    employee.attendance_leaves.where(leave_type: :paid, start_date: year_range)
  end

  def year_range
    Date.new(year, 1, 1)..Date.new(year, 12, 31)
  end
end
