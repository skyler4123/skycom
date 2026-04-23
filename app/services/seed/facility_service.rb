class Seed::FacilityService
  def self.new(
    company:,
    branch: nil,
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
    facility.save!
    facility
  end
end
