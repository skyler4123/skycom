# spec/factories/notification_appointments.rb
FactoryBot.define do
  factory :notification_appointment do
    association :company
    association :notification
    association :appoint_to, factory: :employee

    name { "#{notification.name} Appointment" }
    description { "Notification appointment for #{notification.name}." }
    code { "NOTIF-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { NotificationAppointment.lifecycle_statuses.keys.sample }
    workflow_status { NotificationAppointment.workflow_statuses.keys.sample }
    business_type { NotificationAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::NotificationAppointmentService.new(
        company: company,
        notification: notification,
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
