class AttendanceRecord < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee
  belongs_to :scheduled_shift, optional: true

  validates :check_in_at, presence: true
end
