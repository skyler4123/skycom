# spec/factories/service_groups.rb
FactoryBot.define do
  factory :service_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::ServiceGroupService.create(branch: branch)
    end

    skip_create
  end
end
