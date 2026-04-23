# spec/factories/facilities.rb
FactoryBot.define do
  factory :facility do
    association :company

    initialize_with do
      Seed::FacilityService.new(company: company)
    end

  end
end
