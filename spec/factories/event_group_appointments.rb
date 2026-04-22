# spec/factories/event_group_appointments.rb
FactoryBot.define do
  factory :event_group_appointment do
    association :company
    association :event_group
    association :appoint_to, factory: :employee

    name { "#{event_group.name} Appointment" }
    description { "Event group appointment for #{event_group.name}." }
    code { "EVGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { EventGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { EventGroupAppointment.workflow_statuses.keys.sample }
    business_type { EventGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::EventGroupAppointmentService.create(
        company: company,
        event_group: event_group,
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

    skip_create
  end
end
