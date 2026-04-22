class Seed::InventoryTransactionService
  def self.create(
    company:,
    branch: nil,
    inventory: nil,
    appoint_from: nil,
    appoint_to:,
    name: nil,
    description: nil,
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create inventory transaction: No company provided." if company.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    InventoryTransaction.create!(
      company: company,
      branch: branch,
      inventory: inventory,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      name: name || "InventoryTransaction #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "INVTXN-#{SecureRandom.hex(4).upcase}",
      status: status || InventoryTransaction.statuses.keys.sample,
      business_type: business_type || InventoryTransaction.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
