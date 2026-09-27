# spec/factories/customer_customer_group_appointments.rb
FactoryBot.define do
  factory :customer_customer_group_appointment do
    association :company
    association :customer
    association :customer_group

    initialize_with do
      Seed::CustomerCustomerGroupAppointmentService.new(company: company, customer: customer, customer_group: customer_group)
    end
  end
end
