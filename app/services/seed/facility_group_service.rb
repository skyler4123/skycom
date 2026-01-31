# This service seeds the database with FacilityGroup records. Each group is
# associated with a Company and can be used to organize facilities.

class Seed::FacilityGroupService
  def self.create(
    company_group:,
    company: nil,
    name: Faker::Commerce.department,
    description: Faker::Lorem.sentence(word_count: 10),
    code: Faker::Code.npi,
    lifecycle_status: FacilityGroup.lifecycle_statuses.keys.sample,
    workflow_status: FacilityGroup.workflow_statuses.keys.sample,
    business_type: FacilityGroup.business_types.keys.sample,
    discarded_at: nil
  )
    FacilityGroup.create!(
      company_group: company_group,
      company: company,
      name: name,
      description: description,
      code: code,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
