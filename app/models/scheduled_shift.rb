# frozen_string_literal: true

# ScheduledShift — Atomic purpose: one employee's scheduled work shift on a
# specific date and branch.
#
# Why it exists: attendance and payroll need the expected shift (start/end,
# template) to compare against actual punches.
# How it works: belongs to company/branch/employee and optional shift_template;
# work_date, expected_start_at, and expected_end_at are required; status moves
# scheduled → active → completed.
# Main associations: belongs_to :company, :branch, :employee (required),
# :shift_template (optional).
class ScheduledShift < ApplicationRecord
  enum :status, { scheduled: 0, active: 1, completed: 2 }, prefix: true, default: :scheduled

  belongs_to :company
  belongs_to :branch
  belongs_to :employee
  belongs_to :shift_template, optional: true

  validates :work_date, :expected_start_at, :expected_end_at, presence: true
  validates :status, presence: true
end
