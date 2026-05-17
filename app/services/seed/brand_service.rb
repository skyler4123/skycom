class Seed::BrandService
  def self.new(company:, name:)
    # Get enum keys once before the loop for efficiency.
    lifecycle_statuses = Brand.lifecycle_statuses.keys
    workflow_statuses = Brand.workflow_statuses.keys
    business_types = Brand.business_types.keys

    Brand.new(
      company: company,
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
    brand.save!
    brand
  end
end
