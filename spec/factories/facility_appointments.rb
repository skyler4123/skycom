# spec/factories/facility_appointments.rb
FactoryBot.define do
  factory :facility_appointment do
    association :company
    association :facility
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::FacilityAppointmentService.new(company: company, facility: facility, appoint_to: appoint_to)
    end
  end
end
