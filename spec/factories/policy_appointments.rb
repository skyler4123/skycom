# spec/factories/policy_appointments.rb
FactoryBot.define do
  factory :policy_appointment do
    association :policy
    association :appoint_to, factory: :employee

    name { "#{policy.name} Appointment" }
    description { "Policy appointment for #{policy.name}." }
    code { "POL-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { PolicyAppointment.lifecycle_statuses.keys.sample }
    workflow_status { PolicyAppointment.workflow_statuses.keys.sample }
    business_type { PolicyAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::PolicyAppointmentService.new(
        policy: policy,
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
