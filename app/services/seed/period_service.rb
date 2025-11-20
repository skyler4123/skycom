# This service seeds the database with Period records. Each period is
# associated with a Company and includes date ranges. It also simulates
# soft deletion for a portion of the records.

class Seed::PeriodService
  # Configuration for the number of periods to create per company
  PERIODS_PER_COMPANY = 4

  def self.run
    puts "Seeding Period records..."

    Company.all.each do |company|
      PERIODS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        start_date = Faker::Date.between(from: 2.years.ago, to: 1.year.from_now)
        end_date = Faker::Date.between(from: start_date, to: start_date + 1.year)
        duration_in_days = (end_date - start_date).to_i

        Period.create!(
          company: company,
          name: "Time Period ##{i + 1}",
          description: Faker::Lorem.sentence(word_count: 8),
          code: "PER-#{SecureRandom.hex(3).upcase}",
          duration: duration_in_days,
          start_at: start_date.to_datetime,
          end_at: end_date.to_datetime,
          expire_at: end_date.to_datetime + 30.days,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Period.count} Period records."
  end
end