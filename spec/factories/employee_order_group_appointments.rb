FactoryBot.define do
  factory :employee_order_group_appointment do
    association :company
    association :order_group
    association :employee

    initialize_with do
      Seed::EmployeeOrderGroupAppointmentService.create(company: company, order_group: order_group, employee: employee)
    end
  end
end
