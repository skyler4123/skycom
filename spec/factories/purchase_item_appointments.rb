# spec/factories/purchase_item_appointments.rb
FactoryBot.define do
  factory :purchase_item_appointment do
    association :purchase_item
    association :purchase

    initialize_with do
      Seed::PurchaseItemAppointmentService.new(
        company: purchase.company,
        purchase: purchase,
        purchase_item: purchase_item
      )
    end
  end
end
