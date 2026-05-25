# spec/factories/event_appointments.rb
FactoryBot.define do
  factory :event_appointment do
    association :company
    association :event
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::EventAppointmentService.new(company: company, event: event, appoint_to: appoint_to)
    end
  end
end
