class Seed::InventoryService
  def self.create(
    company:,
    branch: nil,
    name: nil,
    description: nil,
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    Inventory.create!(
      company: company,
      branch: branch,
      name: name || "Inventory #{Faker::Lorem.sentence(word_count: 2)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "INV-#{SecureRandom.hex(4).upcase}",
      status: status || Inventory.statuses.keys.sample,
      business_type: business_type || Inventory.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
