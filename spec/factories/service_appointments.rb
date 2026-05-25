# spec/factories/service_appointments.rb
FactoryBot.define do
  factory :service_appointment do
    association :company
    association :service
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ServiceAppointmentService.new(company: company, service: service, appoint_to: appoint_to)
    end
  end
end
