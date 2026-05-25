# spec/factories/order_appointments.rb
FactoryBot.define do
  factory :order_appointment do
    association :company
    association :order
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::OrderAppointmentService.new(company: company, order: order, appoint_to: appoint_to)
    end
  end
end
