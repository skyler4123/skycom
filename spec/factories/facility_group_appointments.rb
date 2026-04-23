# spec/factories/facility_group_appointments.rb
FactoryBot.define do
  factory :facility_group_appointment do
    association :company
    association :facility_group
    association :appoint_to, factory: :employee

    name { "#{facility_group.name} Appointment" }
    description { "Facility group appointment for #{facility_group.name}." }
    code { "FGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { FacilityGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { FacilityGroupAppointment.workflow_statuses.keys.sample }
    business_type { FacilityGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::FacilityGroupAppointmentService.new(
        company: company,
        facility_group: facility_group,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

  end
end
