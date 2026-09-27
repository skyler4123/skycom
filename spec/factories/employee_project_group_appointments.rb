# spec/factories/employee_project_group_appointments.rb
FactoryBot.define do
  factory :employee_project_group_appointment do
    association :company
    association :employee
    association :project_group

    initialize_with do
      Seed::EmployeeProjectGroupAppointmentService.new(company: company, employee: employee, project_group: project_group)
    end
  end
end
