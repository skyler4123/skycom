# spec/factories/order_group_appointments.rb
FactoryBot.define do
  factory :order_group_appointment do
    association :company
    association :order_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::OrderGroupAppointmentService.new(company: company, order_group: order_group, appoint_to: appoint_to)
    end
  end
end
