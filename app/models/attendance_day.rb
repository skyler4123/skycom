# frozen_string_literal: true

# AttendanceDay — Atomic purpose: one employee's aggregated attendance for one
# calendar day (present/late/absent, worked/break/overtime seconds).
#
# Why it exists: the day is the reporting unit for attendance and payroll; it
# aggregates the raw check-in/out logs without recomputing on every read.
# How it works: belongs to company/branch/employee; attendance_date is required.
# attendance_status and recorded_method are enums; totals are stored as seconds.
# Main associations: belongs_to :company, :employee (required), :branch (optional).
class AttendanceDay < ApplicationRecord
  attribute :total_seconds_present, :integer, default: 0
  attribute :total_seconds_break, :integer, default: 0
  attribute :total_seconds_worked, :integer, default: 0
  attribute :total_seconds_overtime, :integer, default: 0

  # --- Enums ---
  enum :attendance_status, { present: 0, half_day: 1, late: 2, absent: 3, missing_checkout: 4 }, prefix: true
  enum :recorded_method, { check_in: 0, request: 1 }, prefix: true
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :attendance_date, presence: true
end
