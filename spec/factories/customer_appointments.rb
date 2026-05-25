# spec/factories/customer_appointments.rb
FactoryBot.define do
  factory :customer_appointment do
    association :company
    association :customer
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::CustomerAppointmentService.new(company: company, customer: customer, appoint_to: appoint_to)
    end
  end
end
