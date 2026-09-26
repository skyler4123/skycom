# spec/factories/department_employee_appointments.rb
FactoryBot.define do
  factory :department_employee_appointment do
    association :company
    association :department
    association :employee

    initialize_with do
      Seed::DepartmentEmployeeAppointmentService.new(company: company, department: department, employee: employee)
    end
  end
end
