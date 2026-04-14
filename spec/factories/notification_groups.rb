# spec/factories/notification_groups.rb
FactoryBot.define do
  factory :notification_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::NotificationGroupService.create(branch: branch)
    end

    skip_create
  end
end
