class Seed::EventService
  def self.new(
    company:,
    branch: nil,
    event_group: nil,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    code: nil,
    start_at: nil,
    end_at: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    branch ||= event_group&.branch
    company ||= event_group&.company

    start_at ||= Faker::Time.forward(days: 30)
    Event.new(
      company: company,
      branch: branch,
      event_group: event_group,
      category: category,
      property_mapping: property_mapping,
      name: name || "Event #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "EVT-#{SecureRandom.hex(4).upcase}",
      start_at: start_at,
      end_at: end_at || start_at + 1.hour,
      workflow_status: workflow_status || Event.workflow_statuses.keys.sample,
      business_type: business_type || Event.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    event = new(...)
    event.branch ||= event.event_group&.branch
    event.company ||= event.event_group&.company
    if event.category.nil? && event.company.present?
      event.category = Seed::CategoryService.random_for(
        company: event.company,
        resource_name: Event.model_name.plural
      )
    end
    if event.property_mapping.nil? && event.category.present?
      event.property_mapping = event.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(event)
    event.save!
    event
  end
end
