# spec/factories/bookings.rb
FactoryBot.define do
  factory :booking do
    association :company
    association :appoint_to

    appoint_from { nil }
    name { Faker::Book.title }
    description { Faker::Lorem.sentence }
    code { Faker::Code.npi }
    lifecycle_status { Booking.lifecycle_statuses.keys.sample }
    workflow_status { Booking.workflow_statuses.keys.sample }
    business_type { Booking.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::BookingService.new(
        branch: branch,
        appoint_from: appoint_from,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end
  end
end
