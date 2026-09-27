# spec/factories/employee_facility_appointments.rb
FactoryBot.define do
  factory :employee_facility_appointment do
    association :company
    association :employee
    association :facility

    initialize_with do
      Seed::EmployeeFacilityAppointmentService.new(company: company, employee: employee, facility: facility)
    end
  end
end
