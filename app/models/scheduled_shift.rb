class ScheduledShift < ApplicationRecord
  belongs_to :company
  belongs_to :branch
  belongs_to :employee
  belongs_to :shift_template, optional: true

  validates :work_date, :expected_start_at, :expected_end_at, presence: true
  validates :status, presence: true
end
