# spec/factories/customer_group_appointments.rb
FactoryBot.define do
  factory :customer_group_appointment do
    association :company
    association :customer_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::CustomerGroupAppointmentService.new(company: company, customer_group: customer_group, appoint_to: appoint_to)
    end
  end
end
