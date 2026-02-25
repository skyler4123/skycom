# This service seeds the database with CartGroup records. Each group is
# associated with a Company and can be used to organize carts.

class Seed::CartGroupService
  def self.create(
    branch: Company.all.sample,
    name: "#{Faker::Commerce.department} Carts",
    description: "A group for carts related to #{Faker::Marketing.buzzwords}.",
    code: Faker::Code.npi,
    lifecycle_status: CartGroup.lifecycle_statuses.keys.sample,
    workflow_status: CartGroup.workflow_statuses.keys.sample,
    business_type: CartGroup.business_types.keys.sample,
    discarded_at: nil
  )
    CartGroup.create!(
      branch: branch,
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
