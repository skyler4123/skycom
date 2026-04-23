# spec/factories/task_group_appointments.rb
FactoryBot.define do
  factory :task_group_appointment do
    association :company
    association :task_group
    association :appoint_to, factory: :employee

    name { "#{task_group.name} Appointment" }
    description { "Task group appointment for #{task_group.name}." }
    code { "TKGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { TaskGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { TaskGroupAppointment.workflow_statuses.keys.sample }
    business_type { TaskGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::TaskGroupAppointmentService.new(
        company: company,
        task_group: task_group,
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
