# spec/factories/branch_payment_method_appointments.rb
FactoryBot.define do
  factory :branch_payment_method_appointment do
    association :payment_method
    association :branch
    company { branch.company }

    initialize_with do
      Seed::PaymentMethodAppointmentService.new(company: company, payment_method: payment_method, branch: branch)
    end
  end
end
