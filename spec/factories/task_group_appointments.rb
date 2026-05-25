# spec/factories/task_group_appointments.rb
FactoryBot.define do
  factory :task_group_appointment do
    association :company
    association :task_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::TaskGroupAppointmentService.new(company: company, task_group: task_group, appoint_to: appoint_to)
    end
  end
end
