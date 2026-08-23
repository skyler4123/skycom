class AttendanceLog < ApplicationRecord
  enum :log_type, { check_in: 0, check_out: 1 }, prefix: true
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :log_type, :logged_at, presence: true
end
