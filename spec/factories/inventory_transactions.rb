# spec/factories/inventory_transactions.rb
FactoryBot.define do
  factory :inventory_transaction do
    association :company
    association :appoint_to

    name { "InventoryTransaction #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "INVTXN-#{SecureRandom.hex(4).upcase}" }
    status { InventoryTransaction.statuses.keys.sample }
    business_type { InventoryTransaction.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::InventoryTransactionService.create(
        company: company,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        status: status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

    skip_create
  end
end
