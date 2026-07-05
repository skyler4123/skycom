class ShiftTemplate < ApplicationRecord
  attribute :grace_period_minutes, :integer, default: 15
  attribute :unpaid_break_minutes, :integer, default: 60
  attribute :policy_type, :string, default: "fixed"
  attribute :full_day_minutes, :integer, default: 480

  belongs_to :company
  belongs_to :branch, optional: true

  validates :name, :start_time, :end_time, presence: true
end
