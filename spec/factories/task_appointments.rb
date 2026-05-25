# spec/factories/task_appointments.rb
FactoryBot.define do
  factory :task_appointment do
    association :company
    association :task
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::TaskAppointmentService.new(company: company, task: task, appoint_to: appoint_to)
    end
  end
end
