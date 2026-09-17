class Seed::SupplierService
  def self.new(company:, category: nil, property_mapping: nil, name:)
    # Get enum keys once before the loop for efficiency.
    lifecycle_statuses = Supplier.lifecycle_statuses.keys
    workflow_statuses = Supplier.workflow_statuses.keys
    business_types = Supplier.business_types.keys

    Supplier.new(
      company: company,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: "Official supplier page for #{name}.",
      code: "SU-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_statuses.sample,
      workflow_status: workflow_statuses.sample,
      business_type: business_types.sample,
    )
  end

  def self.create(...)
    supplier = new(...)
    if supplier.category.nil? && supplier.company.present?
      supplier.category = Seed::CategoryService.random_for(
        company: supplier.company,
        resource_name: Supplier.model_name.plural
      )
    end
    if supplier.property_mapping.nil? && supplier.category.present?
      supplier.property_mapping = supplier.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(supplier)
    supplier.save!
    supplier
  end
end
