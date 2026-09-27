FactoryBot.define do
  factory :cart_employee_appointment do
    association :company
    cart { association :cart, company: company }
    employee { association :employee, company: company }

    initialize_with do
      Seed::CartEmployeeAppointmentService.new(company: company, cart: cart, employee: employee)
    end
  end
end
