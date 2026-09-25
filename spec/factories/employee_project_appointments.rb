# spec/factories/employee_project_appointments.rb
FactoryBot.define do
  factory :employee_project_appointment do
    association :company
    association :employee
    association :project

    initialize_with do
      Seed::EmployeeProjectAppointmentService.new(company: company, employee: employee, project: project)
    end
  end
end
