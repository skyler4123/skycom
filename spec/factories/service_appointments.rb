# spec/factories/service_appointments.rb
FactoryBot.define do
  factory :service_appointment do
    association :company
    association :service
    association :appoint_to, factory: :employee

    name { "#{service.name} Appointment" }
    description { "Service appointment for #{service.name}." }
    code { "SVC-APT-#{SecureRandom.hex(4).upcase}" }
    duration { rand(30..180) }
    start_at { Faker::Time.forward(days: 30) }
    lifecycle_status { ServiceAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ServiceAppointment.workflow_statuses.keys.sample }
    business_type { ServiceAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ServiceAppointmentService.new(
        company: company,
        service: service,
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
