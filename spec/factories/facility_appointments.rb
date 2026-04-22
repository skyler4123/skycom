# spec/factories/facility_appointments.rb
FactoryBot.define do
  factory :facility_appointment do
    association :company
    association :facility
    association :appoint_to, factory: :employee

    name { "#{facility.name} Appointment" }
    description { "Facility appointment for #{facility.name}." }
    code { "FAC-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { FacilityAppointment.lifecycle_statuses.keys.sample }
    workflow_status { FacilityAppointment.workflow_statuses.keys.sample }
    business_type { FacilityAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::FacilityAppointmentService.create(
        company: company,
        facility: facility,
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

    skip_create
  end
end
