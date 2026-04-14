# spec/factories/facilities.rb
FactoryBot.define do
  factory :facility do
    association :company

    initialize_with do
      Seed::FacilityService.create(company: company)
    end

    skip_create
  end
end
