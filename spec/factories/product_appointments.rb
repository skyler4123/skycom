# spec/factories/product_appointments.rb
FactoryBot.define do
  factory :product_appointment do
    association :company
    association :product
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ProductAppointmentService.new(company: company, product: product, appoint_to: appoint_to)
    end
  end
end
