class Seed::ProductService
  def self.new(
    company:,
    branch: nil,
    brand: nil,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    code: nil,
    price: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    business_type ||= Product.business_types.keys.sample
    workflow_status ||= Product.workflow_statuses.keys.sample
    lifecycle_status ||= Product.lifecycle_statuses.keys.sample

    name ||= Faker::Commerce.product_name
    description ||= Faker::Lorem.sentence(word_count: 12)
    code ||= "PRD-#{SecureRandom.hex(4).upcase}"

    # Convert price to cents using money-rails
    raw_price = price || Faker::Commerce.price(range: 50..2000.0)
    price_cents = Money.from_amount(raw_price, company.currency_code&.upcase || "USD").cents

    Product.new(
      company: company,
      branch: branch,
      brand: brand,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: description,
      code: code,
      price_cents: price_cents,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    product = new(...)
    if product.category.nil? && product.company.present?
      product.category = Seed::CategoryService.random_for(
        company: product.company,
        resource_name: Product.model_name.plural
      )
    end
    if product.property_mapping.nil? && product.category.present?
      product.property_mapping = product.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(product)
    product.save!
    Seed::AttachmentService.attach(record: product, relation: :image_attachments, number: 2)
    product
  end
end
