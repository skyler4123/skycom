# spec/factories/service_service_group_appointments.rb
FactoryBot.define do
  factory :service_service_group_appointment do
    association :company
    association :service
    association :service_group

    initialize_with do
      Seed::ServiceServiceGroupAppointmentService.new(company: company, service: service, service_group: service_group)
    end
  end
end
