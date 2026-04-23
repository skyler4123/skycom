# spec/factories/task_appointments.rb
FactoryBot.define do
  factory :task_appointment do
    association :company
    association :task
    association :appoint_to, factory: :employee

    name { "#{task.name} Appointment" }
    description { "Task appointment for #{task.name}." }
    code { "TSK-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { TaskAppointment.lifecycle_statuses.keys.sample }
    workflow_status { TaskAppointment.workflow_statuses.keys.sample }
    business_type { TaskAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::TaskAppointmentService.new(
        company: company,
        task: task,
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
