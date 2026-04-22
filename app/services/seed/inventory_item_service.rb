class Seed::InventoryItemService
  def self.create(
    inventory:,
    name: nil,
    description: nil,
    code: nil,
    sku: nil,
    barcode: nil,
    upc: nil,
    ean: nil,
    manufacturer_code: nil,
    serial_number: nil,
    batch_number: nil,
    expiration_date: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create inventory item: No inventory provided." if inventory.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    InventoryItem.create!(
      inventory: inventory,
      company: inventory.company,
      branch: inventory.branch,
      name: name || Faker::Commerce.product_name,
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "INV-#{SecureRandom.hex(4).upcase}",
      sku: sku || Faker::Number.between(from: 100000, to: 999999).to_s,
      barcode: barcode || Faker::Number.between(from: 1000000000000, to: 9999999999999).to_s,
      upc: upc,
      ean: ean,
      manufacturer_code: manufacturer_code,
      serial_number: serial_number,
      batch_number: batch_number,
      expiration_date: expiration_date,
      status: status || InventoryItem.statuses.keys.sample,
      business_type: business_type || InventoryItem.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
