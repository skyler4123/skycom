# This service seeds the database with CartGroup records. Each group is
# associated with a Company and can be used to organize carts.

class Seed::CartGroupService
  def self.create(
    company: Company.all.sample,
    name: "#{Faker::Commerce.department} Carts",
    description: "A group for carts related to #{Faker::Marketing.buzzwords}.",
    code: nil,
    lifecycle_status: CartGroup.lifecycle_statuses.keys.sample,
    workflow_status: CartGroup.workflow_statuses.keys.sample,
    business_type: CartGroup.business_types.keys.sample,
    discarded_at: nil
  )
    # Randomly decide whether to mark the record as discarded if not specified
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    CartGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "CART-G-#{company.id}-#{SecureRandom.hex(3).upcase}",
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
