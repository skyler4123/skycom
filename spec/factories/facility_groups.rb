# spec/factories/facility_groups.rb
FactoryBot.define do
  factory :facility_group do
    association :company

    initialize_with do
      Seed::FacilityGroupService.new(company: company)
    end

  end
end
