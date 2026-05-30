class Seed::BrandService
  def self.new(company:, category: nil, name:)
    # Get enum keys once before the loop for efficiency.
    lifecycle_statuses = Brand.lifecycle_statuses.keys
    workflow_statuses = Brand.workflow_statuses.keys
    business_types = Brand.business_types.keys

    Brand.new(
      company: company,
      category: category,
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
      brand.category = Seed::CategoryService.find_or_create_for(
        company: brand.company,
        resource_name: Brand.model_name.plural
      )
    end
    brand.save!
    brand
  end
end
