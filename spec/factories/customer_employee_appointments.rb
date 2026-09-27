# spec/factories/customer_employee_appointments.rb
FactoryBot.define do
  factory :customer_employee_appointment do
    association :company
    association :customer
    association :employee

    initialize_with do
      Seed::CustomerEmployeeAppointmentService.new(company: company, customer: customer, employee: employee)
    end
  end
end
