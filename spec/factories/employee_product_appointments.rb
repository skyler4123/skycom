# spec/factories/employee_product_appointments.rb
FactoryBot.define do
  factory :employee_product_appointment do
    association :company
    association :employee
    association :product

    initialize_with do
      Seed::EmployeeProductAppointmentService.new(company: company, employee: employee, product: product)
    end
  end
end
