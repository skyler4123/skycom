class Seed::StockImportService
  def self.new(
    company:,
    branch: nil,
    product:,
    category: nil,
    property_mapping: nil,
    appoint_from: nil,
    appoint_to: nil,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    quantity: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create stock import: No company provided." if company.nil?
    raise "Cannot create stock import: No product provided." if product.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    StockImport.new(
      company: company,
      branch: branch,
      product: product,
      category: category,
      property_mapping: property_mapping,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name || "StockImport #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "STKIM-#{SecureRandom.hex(4).upcase}",
      quantity: quantity || rand(1..100),
      lifecycle_status: lifecycle_status || StockImport.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || StockImport.workflow_statuses.keys.sample,
      business_type: business_type || StockImport.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    stock_import = new(...)
    if stock_import.category.nil? && stock_import.company.present?
      stock_import.category = Seed::CategoryService.random_for(
        company: stock_import.company,
        resource_name: StockImport.model_name.plural
      )
    end
    if stock_import.property_mapping.nil? && stock_import.category.present?
      stock_import.property_mapping = stock_import.category.property_mapping
    end
    Seed::PropertyPopulator.populate(stock_import)
    stock_import.save!
    stock_import
  end
end
