# This service seeds the database with Cart records. Each cart is
# associated with a CartGroup and a Company.

class Seed::CartService
  def self.create(
    company:,
    cart_group: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: Cart.lifecycle_statuses.keys.sample,
    workflow_status: Cart.workflow_statuses.keys.sample,
    business_type: Cart.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "Cart for #{company.name}"
    description ||= "A cart for group '#{cart_group.name}'."
    code ||= "CART-#{company.id}-#{cart_group.id}-#{SecureRandom.hex(2).upcase}"

    Cart.create!(
      company: company,
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
