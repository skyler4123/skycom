class Seed::EventGroupService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    EventGroup.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      name: name || "Event Group #{Faker::Lorem.sentence(word_count: 2)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "EG-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || EventGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || EventGroup.workflow_statuses.keys.sample,
      business_type: business_type || EventGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    if group.category.nil? && group.company.present?
      group.category = Seed::CategoryService.find_or_create_for(
        company: group.company,
        resource_name: EventGroup.model_name.plural
      )
    end
    if group.property_mapping.nil? && group.category.present?
      group.property_mapping = group.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(group)
    group.save!
    group
  end
end
