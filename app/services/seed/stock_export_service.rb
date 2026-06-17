class Seed::StockExportService
  def self.new(
    company:,
    branch: nil,
    warehouse: nil,
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
    raise "Cannot create stock export: No company provided." if company.nil?
    raise "Cannot create stock export: No product provided." if product.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    StockExport.new(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      category: category,
      property_mapping: property_mapping,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name || "StockExport #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "STKEX-#{SecureRandom.hex(4).upcase}",
      quantity: quantity || rand(1..100),
      lifecycle_status: lifecycle_status || StockExport.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || StockExport.workflow_statuses.keys.sample,
      business_type: business_type || StockExport.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    stock_export = new(...)
    if stock_export.category.nil? && stock_export.company.present?
      stock_export.category = Seed::CategoryService.random_for(
        company: stock_export.company,
        resource_name: StockExport.model_name.plural
      )
    end
    if stock_export.property_mapping.nil? && stock_export.category.present?
      stock_export.property_mapping = stock_export.category.property_mapping
    end
    Seed::PropertyPopulator.populate(stock_export)
    stock_export.save!
    stock_export
  end
end
