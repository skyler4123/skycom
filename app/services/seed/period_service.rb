# This service seeds the database with Period records. Each period is
# associated with a Company and includes date ranges. It also simulates
# soft deletion for a portion of the records.

class Seed::PeriodService
  def self.new(
    start_at:,
    end_at:,
    timezone:,
    business_type: :subscription
  )
    Period.new(
      start_at: start_at,
      end_at: end_at,
      timezone: timezone
    )
  end

  def self.create(start_at:, end_at:, timezone:, business_type: :subscription)
    {
      start_at: start_at,
      end_at: end_at,
      timezone: timezone,
      business_type: business_type
    }
  end
end
