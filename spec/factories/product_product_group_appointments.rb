# spec/factories/product_product_group_appointments.rb
FactoryBot.define do
  factory :product_product_group_appointment do
    association :company
    association :product
    association :product_group

    initialize_with do
      Seed::ProductProductGroupAppointmentService.new(company: company, product: product, product_group: product_group)
    end
  end
end
