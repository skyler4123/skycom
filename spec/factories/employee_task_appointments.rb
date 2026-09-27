# spec/factories/employee_task_appointments.rb
FactoryBot.define do
  factory :employee_task_appointment do
    association :company
    association :employee
    association :task

    initialize_with do
      Seed::EmployeeTaskAppointmentService.new(company: company, employee: employee, task: task)
    end
  end
end
