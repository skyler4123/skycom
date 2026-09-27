# spec/factories/customer_service_appointments.rb
FactoryBot.define do
  factory :customer_service_appointment do
    association :company
    association :customer
    association :service

    initialize_with do
      Seed::CustomerServiceAppointmentService.new(company: company, customer: customer, service: service)
    end
  end
end
