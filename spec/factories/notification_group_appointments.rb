# spec/factories/notification_group_appointments.rb
FactoryBot.define do
  factory :notification_group_appointment do
    association :company
    association :notification_group
    association :appoint_to, factory: :employee

    name { "#{notification_group.name} Appointment" }
    description { "Notification group appointment for #{notification_group.name}." }
    code { "NGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { NotificationGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { NotificationGroupAppointment.workflow_statuses.keys.sample }
    business_type { NotificationGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::NotificationGroupAppointmentService.create(
        company: company,
        notification_group: notification_group,
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
