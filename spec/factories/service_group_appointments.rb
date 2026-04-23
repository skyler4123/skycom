# spec/factories/service_group_appointments.rb
FactoryBot.define do
  factory :service_group_appointment do
    association :company
    association :service_group
    association :appoint_to, factory: :employee

    name { "#{service_group.name} Appointment" }
    description { "Service group appointment for #{service_group.name}." }
    code { "SGR-APT-#{SecureRandom.hex(4).upcase}" }
    duration { rand(30..180) }
    start_at { Faker::Time.forward(days: 30) }
    lifecycle_status { ServiceGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ServiceGroupAppointment.workflow_statuses.keys.sample }
    business_type { ServiceGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ServiceGroupAppointmentService.new(
        company: company,
        service_group: service_group,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        duration: duration,
        start_at: start_at,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end
  end
end
