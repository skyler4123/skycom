# This service seeds the database with CustomerGroup records. Each group is
# associated with a Company and can be used to organize customers.

class Seed::CustomerGroupService
  def self.create(
    company_group:,
    company: nil,
    name: Faker::Name.name,
    description: Faker::Lorem.sentence(word_count: 10),
    code: Faker::Code.npi,
    lifecycle_status: CustomerGroup.lifecycle_statuses.keys.sample,
    workflow_status: CustomerGroup.workflow_statuses.keys.sample,
    business_type: CustomerGroup.business_types.keys.sample,
    discarded_at: nil
  )
    CustomerGroup.create!(
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
