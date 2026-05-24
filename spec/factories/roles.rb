# spec/factories/roles.rb
FactoryBot.define do
  factory :role do
    association :company
    name { Faker::Job.title }

    initialize_with do
      Seed::RoleService.new(
        company: company,
        name: name
      )
    end
  end
end
