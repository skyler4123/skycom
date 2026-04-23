# spec/factories/settings.rb
FactoryBot.define do
  factory :setting do
    association :company
    association :setting_group

    initialize_with do
      Seed::SettingService.new(setting_group: setting_group, company: company)
    end
  end
end
