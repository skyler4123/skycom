# spec/factories/calendar_availability_rules.rb
FactoryBot.define do
  factory :calendar_availability_rule do
    # A rule is owned by EITHER a practitioner OR a location, so the default
    # practitioner must yield to an explicitly supplied location.
    transient do
      with_location { false }
    end

    company { association :company }
    calendar_practitioner { with_location ? nil : association(:calendar_practitioner, company: company) }

    name { "Weekday hours" }
    timezone { "UTC" }
    days_of_week { [ 1, 2, 3, 4, 5 ] }
    start_time { "09:00" }
    end_time { "17:00" }
    priority { 0 }
    is_unavailable { false }
  end

  factory :calendar_availability_location_rule, parent: :calendar_availability_rule do
    transient { with_location { true } }
  end

  factory :calendar_availability_blackout, parent: :calendar_availability_rule do
    name { "Annual leave" }
    is_unavailable { true }
  end
end
