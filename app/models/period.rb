# How to use: Dont update records, always find_or_create_by! to reuse existing periods.
# app/models/period.rb
class Period < ApplicationRecord
  include ImmutableRecordConcern

  has_many :period_prices, dependent: :destroy

  # --- Enums ---
  # 1. Define the Enum with Valid Method Names
  # We map safe names (e.g., :plus_7) to your values (7).
  enum :timezone, TIMEZONES, prefix: true, default: -12

  # 2. Validations
  validates :start_at, presence: true
  validates :timezone, presence: true

  # Uniqueness constraint
  validates :start_at, uniqueness: {
    scope: [ :end_at, :timezone ],
    message: "already exists with this time and offset"
  }

  # 4. Helper: Format the offset for display (e.g., returns "+07:00")
  def formatted_offset
    # timezone returns the string key (e.g., "plus_7"), so we fetch the integer value
    val = Period.time_zones[timezone]
    sign = val >= 0 ? "+" : "-"
    "#{sign}#{val.abs.to_s.rjust(2, '0')}:00"
  end
end
