# spec/factories/event_groups.rb
FactoryBot.define do
  factory :event_group do
    association :company

    initialize_with do
      Seed::EventGroupService.create(company: company)
    end

    skip_create
  end
end
