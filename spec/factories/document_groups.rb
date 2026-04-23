# spec/factories/document_groups.rb
FactoryBot.define do
  factory :document_group do
    association :company

    initialize_with do
      Seed::DocumentGroupService.new(company: company)
    end
  end
end
