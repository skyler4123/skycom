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
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    price ||= Faker::Commerce.price(range: 50..2000.0)
    business_type ||= Product.business_types.keys.sample

    Product.new(
      company: company,
      branch: branch,
      brand: brand,
      name: name,
      description: description,
      price: price,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    product = new(...)
    product.save!
    Seed::AttachmentService.attach(record: product, relation: :image_attachments, number: 2)
    product
  end
end
