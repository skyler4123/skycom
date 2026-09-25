# spec/factories/customer_group_service_appointments.rb
FactoryBot.define do
  factory :customer_group_service_appointment do
    association :company
    association :customer_group
    association :service

    initialize_with do
      Seed::CustomerGroupServiceAppointmentService.new(company: company, customer_group: customer_group, service: service)
    end
  end
end
