# spec/factories/role_appointments.rb
FactoryBot.define do
  factory :role_appointment do
    association :role
    association :appoint_to, factory: :employee

    name { "#{role.name} Appointment" }
    description { "Role appointment for #{role.name}." }
    code { "ROLE-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { RoleAppointment.lifecycle_statuses.keys.sample }
    workflow_status { RoleAppointment.workflow_statuses.keys.sample }
    business_type { RoleAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::RoleAppointmentService.new(
        role: role,
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
