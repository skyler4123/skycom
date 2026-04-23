# spec/factories/setting_groups.rb
FactoryBot.define do
  factory :setting_group do
    association :company

    initialize_with do
      Seed::SettingGroupService.new(company: company)
    end

  end
end
