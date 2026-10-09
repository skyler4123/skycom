# spec/factories/documents.rb
FactoryBot.define do
  factory :document do
    association :company

    initialize_with do
      Seed::DocumentService.new(company: company)
    end
  end
end
