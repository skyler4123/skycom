class Seed::StockAdjustmentService
  def self.new(
    company:,
    branch: nil,
    warehouse: nil,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    code: nil,
    direction: nil,
    reason: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create stock adjustment: No company provided." if company.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    StockAdjustment.new(
      company: company,
      branch: branch,
      warehouse: warehouse,
      category: category,
      property_mapping: property_mapping,
      name: name || "StockAdjustment #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "STKAD-#{SecureRandom.hex(4).upcase}",
      direction: direction || StockAdjustment.directions.keys.sample,
      reason: reason || "Stock-take correction",
      lifecycle_status: lifecycle_status || StockAdjustment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || StockAdjustment.workflow_statuses.keys.sample,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    adjustment = new(...)
    if adjustment.category.nil? && adjustment.company.present?
      adjustment.category = Seed::CategoryService.random_for(
        company: adjustment.company,
        resource_name: StockAdjustment.model_name.plural
      )
    end
    if adjustment.property_mapping.nil? && adjustment.category.present?
      adjustment.property_mapping = adjustment.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(adjustment)
    adjustment.save!
    adjustment
  end
end
