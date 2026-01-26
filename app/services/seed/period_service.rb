# This service seeds the database with Period records. Each period is
# associated with a Company and includes date ranges. It also simulates
# soft deletion for a portion of the records.

class Seed::PeriodService
  def self.create(
    company:,
    name: "Time Period",
    description: Faker::Lorem.sentence(word_count: 8),
    code: nil,
    start_at: Faker::Date.between(from: 2.years.ago, to: 1.year.from_now).to_datetime,
    end_at: nil,
    discarded_at: nil
  )
    end_at ||= Faker::Date.between(from: start_at, to: start_at + 1.year).to_datetime
    duration_in_days = (end_at.to_date - start_at.to_date).to_i

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Period.create!(
      company: company,
      name: name,
      description: description,
      code: code || "PER-#{SecureRandom.hex(3).upcase}",
      duration: duration_in_days,
      start_at: start_at,
      end_at: end_at,
      expire_at: end_at + 30.days,
      discarded_at: discarded_at
    )
  end
end
