class Seed::WarehouseService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    address: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    Warehouse.new(
      company: company,
      branch: branch,
      category: category,
      address: address,
      name: name || "Warehouse #{Faker::Lorem.sentence(word_count: 2)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "WH-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || Warehouse.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Warehouse.workflow_statuses.keys.sample,
      business_type: business_type || Warehouse.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    warehouse = new(...)
    warehouse.save!
    warehouse
  end
end