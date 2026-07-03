class AttendanceDay < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :attendance_date, presence: true
end
