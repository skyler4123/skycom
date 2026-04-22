# spec/factories/setting_appointments.rb
FactoryBot.define do
  factory :setting_appointment do
    association :company
    association :setting
    association :appoint_to, factory: :employee

    name { "#{setting.name} Appointment" }
    description { "Setting appointment for #{setting.name}." }
    code { "SET-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { SettingAppointment.lifecycle_statuses.keys.sample }
    workflow_status { SettingAppointment.workflow_statuses.keys.sample }
    business_type { SettingAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::SettingAppointmentService.create(
        company: company,
        setting: setting,
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
