class Seed::FacilityService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    name: Faker::Commerce.department,
    description: Faker::Lorem.sentence(word_count: 10),
    lifecycle_status: Facility.lifecycle_statuses.keys.sample,
    workflow_status: Facility.workflow_statuses.keys.sample,
    business_type: Facility.business_types.keys.sample,
    discarded_at: nil
  )
    Facility.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    facility = new(...)
    if facility.category.nil? && facility.company.present?
      facility.category = Seed::CategoryService.random_for(
        company: facility.company,
        resource_name: Facility.model_name.plural
      )
    end
    if facility.property_mapping.nil? && facility.category.present?
      facility.property_mapping = facility.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(facility)
    facility.save!
    facility
  end
end
