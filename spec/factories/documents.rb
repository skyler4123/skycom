# spec/factories/documents.rb
FactoryBot.define do
  factory :document do
    association :company
    association :document_group

    initialize_with do
      Seed::DocumentService.create(company: company, document_group: document_group)
    end

    skip_create
  end
end
