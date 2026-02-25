# This service seeds the database with Facility records, ensuring each facility
# is associated with an existing Company. It uses enums if they are defined
# in the Facility model and simulates soft deletion for a portion of the records.

class Seed::FacilityService
  def self.create(
    company_group:,
    branch: nil,
    name: Faker::Commerce.department,
    description: Faker::Lorem.sentence(word_count: 10),
    lifecycle_status: Facility.lifecycle_statuses.keys.sample,
    workflow_status: Facility.workflow_statuses.keys.sample,
    business_type: Facility.business_types.keys.sample,
    discarded_at: nil
  )
    Facility.create!(
      company_group: company_group,
      branch: branch,
      name: name,
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
