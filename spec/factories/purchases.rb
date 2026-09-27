# spec/factories/purchases.rb
FactoryBot.define do
  factory :purchase do
    association :company
    branch { association :branch, company: company }
    warehouse { association :warehouse, company: company, branch: branch }
    name { "Purchase #{SecureRandom.hex(4)}" }

    initialize_with do
      # Category + property_mapping resolve at save via CategoryConcern/PropertyMappingConcern,
      # so a `category:` override stays consistent with its own mapping.
      Seed::PurchaseService.new(company: company, branch: branch, name: name, warehouse: warehouse)
    end
  end
end
