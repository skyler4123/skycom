FactoryBot.define do
  factory :order_service_appointment do
    association :company
    association :order
    association :service

    initialize_with do
      Seed::OrderServiceAppointmentService.new(company: company, order: order, service: service)
    end
  end
end
