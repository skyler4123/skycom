class Seed::ServiceService
  def self.new(
    company:,
    branch:,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 10),
    lifecycle_status: Service.lifecycle_statuses.keys.sample,
    workflow_status: Service.workflow_statuses.keys.sample,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Service.new(
      company: company,
      branch: branch,
      name: name || "#{branch.name} Service",
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type || Service.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    service = new(...)
    service.save!
    service
  end
end
