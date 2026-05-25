# spec/factories/cart_appointments.rb
FactoryBot.define do
  factory :cart_appointment do
    association :company
    association :cart
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::CartAppointmentService.new(company: company, cart: cart, appoint_to: appoint_to)
    end
  end
end
