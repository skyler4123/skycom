# spec/factories/payment_method_appointments.rb
FactoryBot.define do
  factory :payment_method_appointment do
    association :company
    association :payment_method

    initialize_with do
      Seed::PaymentMethodAppointmentService.new(company: company, payment_method: payment_method)
    end
  end
end
