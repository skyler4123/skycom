# spec/factories/employee_service_appointments.rb
FactoryBot.define do
  factory :employee_service_appointment do
    association :company
    association :employee
    association :service

    initialize_with do
      Seed::EmployeeServiceAppointmentService.new(company: company, employee: employee, service: service)
    end
  end
end
