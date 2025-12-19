# This service seeds the database with Cart records. Each cart is
# associated with a CartGroup and a Company.

class Seed::CartService
  # Configuration for the number of carts to create per cart group
  CARTS_PER_GROUP = 5

  def self.run
    puts "Seeding Cart records..."

    # Get enum keys once before the loop for efficiency.
    lifecycle_statuses = Cart.lifecycle_statuses.keys
    workflow_statuses = Cart.workflow_statuses.keys
    business_types = Cart.business_types.keys

    CartGroup.all.each do |cart_group|
      company = cart_group.company

      CARTS_PER_GROUP.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Cart.create!(
          company: company,
          cart_group: cart_group,
          name: "Cart ##{i + 1} for #{company.name}",
          description: "A cart for group '#{cart_group.name}'.",
          code: "CART-#{company.id}-#{cart_group.id}-#{SecureRandom.hex(2).upcase}",
          lifecycle_status: lifecycle_statuses.sample,
          workflow_status: workflow_statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Cart.count} Cart records."
  end

  def self.create(
    company:,
    cart_group: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Cart.create!(
      company: company,
      cart_group: cart_group,
      name: name || "Cart for #{company.name}",
      description: description || "A cart for group '#{cart_group.name}'.",
      code: code || "CART-#{company.id}-#{cart_group.id}-#{SecureRandom.hex(2).upcase}",
      lifecycle_status: lifecycle_status || Cart.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Cart.workflow_statuses.keys.sample,
      business_type: business_type || Cart.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
