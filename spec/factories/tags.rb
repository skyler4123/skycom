# spec/factories/tags.rb
FactoryBot.define do
  factory :tag do
    association :company

    initialize_with do
      Seed::TagService.create(company: company)
    end

    skip_create
  end
end
