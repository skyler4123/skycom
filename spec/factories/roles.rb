# spec/factories/roles.rb
FactoryBot.define do
  factory :role do
    association :company
    name { Faker::Job.title }

    transient do
      role_business_type { nil }
    end

    initialize_with do
      Seed::RoleService.new(
        company: company,
        name: name,
        business_type: role_business_type
      )
    end
  end
end
