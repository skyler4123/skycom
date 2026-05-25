# spec/factories/notifications.rb
FactoryBot.define do
  factory :notification do
    association :company
    association :notification_group, company: company

    initialize_with do
      Seed::NotificationService.new(company: company, notification_group: notification_group)
    end
  end
end
