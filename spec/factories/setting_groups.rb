# spec/factories/setting_groups.rb
FactoryBot.define do
  factory :setting_group do
    association :company

    initialize_with do
      Seed::SettingGroupService.create(company: company)
    end

    skip_create
  end
end
