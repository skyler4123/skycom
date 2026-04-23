# spec/factories/event_appointments.rb
FactoryBot.define do
  factory :event_appointment do
    association :company
    association :event
    association :appoint_to, factory: :employee

    name { "#{event.name} Appointment" }
    description { "Event appointment for #{event.name}." }
    code { "EVT-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { EventAppointment.lifecycle_statuses.keys.sample }
    workflow_status { EventAppointment.workflow_statuses.keys.sample }
    business_type { EventAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::EventAppointmentService.new(
        company: company,
        event: event,
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
