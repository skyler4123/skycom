# spec/factories/facility_groups.rb
FactoryBot.define do
  factory :facility_group do
    association :company

    initialize_with do
      Seed::FacilityGroupService.create(company: company)
    end

    skip_create
  end
end
