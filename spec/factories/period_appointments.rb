# spec/factories/period_appointments.rb
FactoryBot.define do
  factory :period_appointment do
    association :period
    association :appoint_to, factory: :employee

    name { "#{period.formatted_offset} Appointment" }
    description { "Period appointment for #{period.formatted_offset}." }
    code { "PRD-APT-#{SecureRandom.hex(4).upcase}" }
    value { period.formatted_offset }
    lifecycle_status { PeriodAppointment.lifecycle_statuses.keys.sample }
    workflow_status { PeriodAppointment.workflow_statuses.keys.sample }
    business_type { PeriodAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::PeriodAppointmentService.new(
        period: period,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        value: value,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end
  end
end
