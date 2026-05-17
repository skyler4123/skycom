class Seed::StockService
  def self.new(
    warehouse:,
    branch: nil,
    category: nil,
    company: nil,
    product_id: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil,
    **kwargs # Ignore extra kwargs for removed columns
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
      product_id: product_id,
      name: name || Faker::Commerce.product_name,
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "STK-#{SecureRandom.hex(4).upcase}",
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
