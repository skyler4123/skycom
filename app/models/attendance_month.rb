class AttendanceMonth < ApplicationRecord
  attribute :total_work_minutes, :integer, default: 0
  attribute :total_late_minutes, :integer, default: 0
  attribute :total_early_leave_minutes, :integer, default: 0
  attribute :total_overtime_minutes, :integer, default: 0
  attribute :total_absent_days, :integer, default: 0
  attribute :total_present_days, :integer, default: 0
  attribute :total_records, :integer, default: 0
  attribute :total_deficit_minutes, :integer, default: 0

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :month, presence: true
end
