# spec/factories/calendar_events.rb
FactoryBot.define do
  factory :calendar_event do
    company { association :company }
    calendar_procedure { association :calendar_procedure, company: company }

    sequence(:title) { |n| "Appointment #{n}" }
    description { Faker::Lorem.sentence }
    notes { nil }
    location_note { nil }

    # Truncated to the second so a test can build exact back-to-back windows
    # without fighting sub-second drift.
    starts_at { Time.current.change(sec: 0).change(usec: 0) }
    ends_at { starts_at + 60.minutes }
    timezone { "UTC" }
    all_day { false }
    # status is left to the model default (:pending) so specs that care about
    # the lifecycle state it explicitly.
  end
end
