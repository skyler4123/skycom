# spec/factories/service_group_appointments.rb
FactoryBot.define do
  factory :service_group_appointment do
    association :company
    association :service_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ServiceGroupAppointmentService.new(company: company, service_group: service_group, appoint_to: appoint_to)
    end
  end
end
