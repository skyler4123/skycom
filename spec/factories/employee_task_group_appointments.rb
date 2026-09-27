# spec/factories/employee_task_group_appointments.rb
FactoryBot.define do
  factory :employee_task_group_appointment do
    association :company
    association :employee
    association :task_group

    initialize_with do
      Seed::EmployeeTaskGroupAppointmentService.new(company: company, employee: employee, task_group: task_group)
    end
  end
end
