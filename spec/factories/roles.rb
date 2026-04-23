# spec/factories/roles.rb
FactoryBot.define do
  factory :role do
    association :company
    name { Faker::Job.title } # Default name if none is provided

    initialize_with do
      # We pass name explicitly because the service requires it
      Seed::RoleService.new(
        company: company,
        name: name
      )
    end

  end
end
