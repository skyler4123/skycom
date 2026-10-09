class Seed::DocumentGroupService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    title: nil,
    content: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    DocumentGroup.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      title: title || Faker::Lorem.sentence(word_count: 4),
      content: content || { "body" => Faker::Lorem.paragraph(sentence_count: 3) },
      name: name || "Document Group #{Faker::Lorem.sentence(word_count: 2)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "DG-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || DocumentGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || DocumentGroup.workflow_statuses.keys.sample,
      business_type: business_type || DocumentGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    if group.category.nil? && group.company.present?
      group.category = Seed::CategoryService.random_for(
        company: group.company,
        resource_name: DocumentGroup.model_name.plural
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
