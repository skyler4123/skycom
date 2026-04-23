# spec/factories/setting_group_appointments.rb
FactoryBot.define do
  factory :setting_group_appointment do
    association :company
    association :setting_group
    association :appoint_to, factory: :employee

    name { "#{setting_group.name} Appointment" }
    description { "Setting group appointment for #{setting_group.name}." }
    code { "STGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { SettingGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { SettingGroupAppointment.workflow_statuses.keys.sample }
    business_type { SettingGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::SettingGroupAppointmentService.new(
        company: company,
        setting_group: setting_group,
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
