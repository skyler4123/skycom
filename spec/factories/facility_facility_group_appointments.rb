# spec/factories/facility_facility_group_appointments.rb
FactoryBot.define do
  factory :facility_facility_group_appointment do
    association :company
    association :facility
    association :facility_group

    initialize_with do
      Seed::FacilityFacilityGroupAppointmentService.new(company: company, facility: facility, facility_group: facility_group)
    end
  end
end
