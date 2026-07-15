class ShiftTemplate < ApplicationRecord
  attribute :grace_period_minutes, :integer, default: 15
  attribute :unpaid_break_minutes, :integer, default: 60
  enum :policy_type, { fixed: 0, pure_flexible: 1, core_hours_flexible: 2 }, prefix: true, default: :fixed
  attribute :full_day_minutes, :integer, default: 480

  belongs_to :company
  belongs_to :branch, optional: true

  validates :name, :start_time, :end_time, presence: true
end
