class AttendanceDay < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  enum :attendance_status, { present: 0, half_day: 1, late: 2, absent: 3, missing_checkout: 4 }, prefix: true

  validates :attendance_date, presence: true
end
