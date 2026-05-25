# spec/factories/facility_group_appointments.rb
FactoryBot.define do
  factory :facility_group_appointment do
    association :company
    association :facility_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::FacilityGroupAppointmentService.new(company: company, facility_group: facility_group, appoint_to: appoint_to)
    end
  end
end
