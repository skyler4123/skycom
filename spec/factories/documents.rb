# spec/factories/documents.rb
FactoryBot.define do
  factory :document do
    association :company
    document_group { association :document_group, company: company }

    initialize_with do
      Seed::DocumentService.new(company: company, document_group: document_group)
    end
  end
end
