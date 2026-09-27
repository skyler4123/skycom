FactoryBot.define do
  factory :order_product_appointment do
    association :company
    association :order
    association :product

    initialize_with do
      Seed::OrderProductAppointmentService.new(company: company, order: order, product: product)
    end
  end
end
