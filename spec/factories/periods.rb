# spec/factories/periods.rb
FactoryBot.define do
  factory :period do
    start_at { Time.current.beginning_of_day }
    end_at { Time.current.end_of_day + 1.months }
    timezone { -12 }

    initialize_with do
      Seed::PeriodService.create(
        start_at: start_at,
        end_at: end_at,
        timezone: timezone
      )
    end

    skip_create
  end
end
