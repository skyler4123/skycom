class Seed::BrandService
  def self.new(company:, category: nil, property_mapping: nil, name:)
    # Get enum keys once before the loop for efficiency.
    lifecycle_statuses = Brand.lifecycle_statuses.keys
    workflow_statuses = Brand.workflow_statuses.keys
    business_types = Brand.business_types.keys

    Brand.new(
      company: company,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: "Official brand page for #{name}.",
      code: "BR-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_statuses.sample,
      workflow_status: workflow_statuses.sample,
      business_type: business_types.sample,
    )
  end

  def self.create(...)
    brand = new(...)
    if brand.category.nil? && brand.company.present?
      brand.category = Seed::CategoryService.random_for(
        company: brand.company,
        resource_name: Brand.model_name.plural
      )
    end
    if brand.property_mapping.nil? && brand.category.present?
      brand.property_mapping = brand.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(brand)
    brand.save!
    Seed::AttachmentService.attach(record: brand, relation: :image_attachments, number: 2)
    brand
  end
end
