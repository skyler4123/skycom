# spec/factories/service_groups.rb
FactoryBot.define do
  factory :service_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::ServiceGroupService.new(branch: branch)
    end

  end
end
