# spec/factories/product_group_appointments.rb
FactoryBot.define do
  factory :product_group_appointment do
    association :company
    association :product_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ProductGroupAppointmentService.new(company: company, product_group: product_group, appoint_to: appoint_to)
    end
  end
end
