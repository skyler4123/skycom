class AttendanceDay < ApplicationRecord
  attribute :total_seconds_present, :integer, default: 0
  attribute :total_seconds_break, :integer, default: 0
  attribute :total_seconds_worked, :integer, default: 0
  attribute :total_seconds_overtime, :integer, default: 0

  enum :attendance_status, { present: 0, half_day: 1, late: 2, absent: 3, missing_checkout: 4 }, prefix: true
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :attendance_date, presence: true
end
