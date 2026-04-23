# spec/factories/project_group_appointments.rb
FactoryBot.define do
  factory :project_group_appointment do
    association :company
    association :project_group
    association :appoint_to, factory: :employee

    name { "#{project_group.name} Appointment" }
    description { "Project group appointment for #{project_group.name}." }
    code { "PJGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { ProjectGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ProjectGroupAppointment.workflow_statuses.keys.sample }
    business_type { ProjectGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ProjectGroupAppointmentService.new(
        company: company,
        project_group: project_group,
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
