class AttendanceLog < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  enum :log_type, { check_in: 0, check_out: 1 }, prefix: true

  validates :log_type, :logged_at, presence: true
end
