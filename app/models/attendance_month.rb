class AttendanceMonth < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :month, presence: true
end
