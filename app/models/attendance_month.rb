# frozen_string_literal: true

# AttendanceMonth — Atomic purpose: monthly attendance rollup for one employee
# (worked/late/early/overtime/absent totals).
#
# Why it exists: payroll and HR dashboards need a stable monthly aggregate; this
# row is the month-level counterpart of AttendanceDay.
# How it works: belongs to company/branch/employee; month is required; totals are
# stored minutes/days and are derived from the day and log data.
# Main associations: belongs_to :company, :employee (required), :branch (optional).
class AttendanceMonth < ApplicationRecord
  attribute :total_work_minutes, :integer, default: 0
  attribute :total_late_minutes, :integer, default: 0
  attribute :total_early_leave_minutes, :integer, default: 0
  attribute :total_overtime_minutes, :integer, default: 0
  attribute :total_absent_days, :integer, default: 0
  attribute :total_present_days, :integer, default: 0
  attribute :total_records, :integer, default: 0
  attribute :total_deficit_minutes, :integer, default: 0

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :month, presence: true
end
