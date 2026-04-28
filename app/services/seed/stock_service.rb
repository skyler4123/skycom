class Seed::StockService
  def self.new(
    warehouse:,
    branch: nil,
    category: nil,
    company: nil,
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
    quantity: nil,
    expiration_date: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create stock: No warehouse provided." if warehouse.nil?

    company ||= warehouse.company
    branch ||= warehouse.branch

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Stock.new(
      warehouse: warehouse,
      company: company,
      branch: branch,
      category: category,
      name: name || Faker::Commerce.product_name,
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "STK-#{SecureRandom.hex(4).upcase}",
      sku: sku || Faker::Number.between(from: 100000, to: 999999).to_s,
      barcode: barcode || Faker::Number.between(from: 1000000000000, to: 9999999999999).to_s,
      upc: upc,
      ean: ean,
      manufacturer_code: manufacturer_code,
      serial_number: serial_number,
      batch_number: batch_number,
      quantity: quantity || rand(0..1000),
      expiration_date: expiration_date,
      lifecycle_status: lifecycle_status || Stock.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Stock.workflow_statuses.keys.sample,
      business_type: business_type || Stock.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    stock = new(...)
    stock.save!
    stock
  end
end