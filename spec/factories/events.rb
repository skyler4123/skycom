# spec/factories/events.rb
FactoryBot.define do
  factory :event do
    association :company
    association :event_group

    initialize_with do
      Seed::EventService.create(company: company, event_group: event_group)
    end

    skip_create
  end
end
