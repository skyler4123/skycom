# frozen_string_literal: true

# ShiftTemplate — Atomic purpose: reusable shift definition (start/end, grace,
# unpaid break, full-day minutes, flexibility policy).
#
# Why it exists: branches reuse the same shift patterns; templates keep those
# rules in one place instead of copying times onto every ScheduledShift.
# How it works: belongs to company and optional branch; name/start_time/end_time
# are required; policy_type selects fixed, pure flexible, or core-hours flexible.
# Main associations: belongs_to :company (required), :branch (optional).
class ShiftTemplate < ApplicationRecord
  attribute :grace_period_minutes, :integer, default: 15
  attribute :unpaid_break_minutes, :integer, default: 60
  attribute :full_day_minutes, :integer, default: 480
  enum :policy_type, { fixed: 0, pure_flexible: 1, core_hours_flexible: 2 }, prefix: true, default: :fixed

  belongs_to :company
  belongs_to :branch, optional: true

  validates :name, :start_time, :end_time, presence: true
end
