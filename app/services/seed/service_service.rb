class Seed::ServiceService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    name: nil,
    description: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil,
    **kwargs # Ignore extra kwargs for removed columns
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    lifecycle_status ||= Service.lifecycle_statuses.keys.sample
    workflow_status ||= Service.workflow_statuses.keys.sample

    name ||= "Service #{SecureRandom.hex(4)}"
    description ||= Faker::Lorem.sentence(word_count: 10)

    Service.new(
      company: company,
      branch: branch,
      category: category,
      name: name,
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type || Service.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    service = new(...)
    if service.category.nil? && service.company.present?
      service.category = Seed::CategoryService.find_or_create_for(
        company: service.company,
        resource_name: Service.model_name.plural
      )
    end
    Seed::PropertyPopulator.populate(service)
    service.save!
    service
  end
end
