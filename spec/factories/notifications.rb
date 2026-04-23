# spec/factories/notifications.rb
FactoryBot.define do
  factory :notification do
    association :company
    association :notification_group, company: company

    name { "Notification #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "NOTIF-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { Notification.lifecycle_statuses.keys.sample }
    workflow_status { Notification.workflow_statuses.keys.sample }
    business_type { Notification.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::NotificationService.new(
        company: company,
        notification_group: notification_group,
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
