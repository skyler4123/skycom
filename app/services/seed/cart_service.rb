# This service seeds the database with Cart records. Each cart is
# associated with a CartGroup and a Branch.

class Seed::CartService
  def self.create(
    branch:,
    cart_group: nil,
    name: Faker::Book.title,
    description: Faker::Lorem.sentence,
    code: Faker::Code.npi,
    lifecycle_status: Cart.lifecycle_statuses.keys.sample,
    workflow_status: Cart.workflow_statuses.keys.sample,
    business_type: Cart.business_types.keys.sample,
    discarded_at: nil
  )
    Cart.create!(
      branch: branch,
      cart_group: cart_group,
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
