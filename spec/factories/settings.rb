# spec/factories/settings.rb
FactoryBot.define do
  factory :setting do
    association :company

    initialize_with do
      Seed::SettingService.new(company: company, appoint_to: company)
    end
  end
end
