# spec/factories/project_appointments.rb
FactoryBot.define do
  factory :project_appointment do
    association :company
    association :project
    association :appoint_to, factory: :employee

    name { "#{project.name} Appointment" }
    description { "Project appointment for #{project.name}." }
    code { "PROJ-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { ProjectAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ProjectAppointment.workflow_statuses.keys.sample }
    business_type { ProjectAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ProjectAppointmentService.create(
        company: company,
        project: project,
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
