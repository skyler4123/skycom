class Seed::PurchaseItemService
  def self.new(
    company:,
    category: nil,
    product: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    code: nil,
    unit: nil,
    estimated_unit_price: nil,
    lifecycle_status: :active,
    discarded_at: nil
  )
    raise "Cannot create purchase item: No company provided." if company.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    PurchaseItem.new(
      company: company,
      category: category,
      product: product,
      property_mapping: property_mapping,
      name: name || "Purchase Item #{Faker::Commerce.product_name}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "PI-#{SecureRandom.hex(4).upcase}",
      unit: unit || %w[piece box pack set].sample,
      estimated_unit_price: estimated_unit_price || Faker::Commerce.price(range: 0.5..50.0),
      lifecycle_status: lifecycle_status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    purchase_item = new(...)
    if purchase_item.category.nil? && purchase_item.company.present?
      purchase_item.category = Seed::CategoryService.random_for(
        company: purchase_item.company,
        resource_name: PurchaseItem.model_name.plural
      )
    end
    if purchase_item.property_mapping.nil? && purchase_item.category.present?
      purchase_item.property_mapping = purchase_item.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(purchase_item)
    purchase_item.save!
    purchase_item
  end
end
