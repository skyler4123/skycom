class AttendanceLog < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :log_type, :logged_at, presence: true
end
