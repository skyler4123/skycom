# spec/factories/tags.rb
FactoryBot.define do
  factory :tag do
    association :company

    initialize_with do
      Seed::TagService.new(company: company)
    end
  end
end
