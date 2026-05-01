# This service seeds the database with Period records. Each period is
# associated with a Company and includes date ranges. It also simulates
# soft deletion for a portion of the records.

class Seed::PeriodService
  def self.create
    {
      start_at: Time.current.beginning_of_day,
      end_at: Time.current.end_of_day + 1.months,
      timezone: -12,
      business_type: :subscription
    }
  end
end
