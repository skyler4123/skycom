class Seed::ProductService
  def self.new(
    company:,
    branch: nil,
    brand: (Brand.all + [ nil ]).sample,
    name: Faker::Commerce.product_name,
    description: Faker::Lorem.sentence(word_count: 12),
    price: nil,
    lifecycle_status: Product.lifecycle_statuses.keys.sample,
    workflow_status: Product.workflow_statuses.keys.sample,
    business_type: nil,
    discarded_at: nil,
    # Physical Properties
    material: nil,
    color: nil,
    size: nil,
    shape: nil,
    pattern: nil,
    flavor_scent: nil,
    # Dimensions & Logistics
    weight: nil,
    length: nil,
    width: nil,
    height: nil,
    volume: nil,
    unit_type: "piece",
    # Manufacturing & Origin
    origin_country: nil,
    manufacturer_name: nil,
    model_year: nil,
    warranty_info: nil,
    # Industry Specifics
    duration_value: nil,
    duration_unit: nil,
    capacity: nil,
    is_recurring: false,
    required_role_id: nil,
    # Other Identifiers
    code: nil,
    sku: nil,
    barcode: nil,
    expiration_date: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    business_type ||= Product.business_types.keys.sample

    # Default price: convert Faker float to hash with company currency
    raw_price = price || Faker::Commerce.price(range: 50..2000.0)
    price_hash = {
      amount: raw_price,
      currency_code: company.currency_code
    }

    # Build product without setting price yet
    product = Product.new(
      company: company,
      branch: branch,
      brand: brand,
      name: name,
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at,
      # Physical Properties
      material: material,
      color: color,
      size: size,
      shape: shape,
      pattern: pattern,
      flavor_scent: flavor_scent,
      # Dimensions & Logistics
      weight: weight,
      length: length,
      width: width,
      height: height,
      volume: volume,
      unit_type: unit_type,
      # Manufacturing & Origin
      origin_country: origin_country,
      manufacturer_name: manufacturer_name,
      model_year: model_year,
      warranty_info: warranty_info,
      # Industry Specifics
      duration_value: duration_value,
      duration_unit: duration_unit,
      capacity: capacity,
      is_recurring: is_recurring,
      required_role_id: required_role_id,
      # Other Identifiers
      code: code,
      sku: sku,
      barcode: barcode,
      expiration_date: expiration_date
    )
    # Store price_hash temporarily on the object
    product.singleton_class.attr_accessor :_pending_price_hash
    product._pending_price_hash = price_hash
    product
  end

  def self.create(...)
    product = new(...)
    product.save!
    # Set price after save (uses PriceConcern's setter which creates PriceAppointment)
    if product.respond_to?(:_pending_price_hash) && product._pending_price_hash
      product.price = product._pending_price_hash
      product.save!
    end
    Seed::AttachmentService.attach(record: product, relation: :image_attachments, number: 2)
    product
  end
end
