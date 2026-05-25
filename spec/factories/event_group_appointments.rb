# spec/factories/event_group_appointments.rb
FactoryBot.define do
  factory :event_group_appointment do
    association :company
    association :event_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::EventGroupAppointmentService.new(company: company, event_group: event_group, appoint_to: appoint_to)
    end
  end
end
