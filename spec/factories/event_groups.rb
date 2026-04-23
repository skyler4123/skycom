# spec/factories/event_groups.rb
FactoryBot.define do
  factory :event_group do
    association :company

    initialize_with do
      Seed::EventGroupService.new(company: company)
    end
  end
end
