# This service seeds the database with OrderItemAppointment records, which act
# as line items for existing orders. Each line item is polymorphically linked
# to either a Product or a Service that belongs to the same company as the order.

class Seed::OrderItemAppointmentService

  # Configuration for the number of items to create per order
  ITEMS_PER_ORDER = 3

  def self.run
    # Get enum keys once before the loop for efficiency.
    statuses = OrderItemAppointment.statuses.keys

    puts "Seeding OrderItemAppointment records..."

    Order.all.each do |order|
      company = order.company

      # Create a pool of appointable items (Products and Services) from the same company.
      products = company.products.pluck(:id).map { |id| { id: id, type: 'Product' } }
      services = company.services.pluck(:id).map { |id| { id: id, type: 'Service' } }
      appointable_items = products + services

      # Skip this order if there are no products or services to appoint.
      next if appointable_items.empty?

      ITEMS_PER_ORDER.times do
        # Randomly select an item to add to the order.
        item_to_appoint = appointable_items.sample
        quantity = rand(1..5)
        unit_price = Faker::Commerce.price(range: 10..500.0)

        OrderItemAppointment.create!(
          order: order,
          appoint_to_id: item_to_appoint[:id],
          appoint_to_type: item_to_appoint[:type],
          name: "Order Item for #{item_to_appoint[:type]} ##{item_to_appoint[:id]}",
          description: Faker::Lorem.sentence,
          quantity: quantity,
          unit_price: unit_price,
          status: statuses.sample
        )
      end
    end

    puts "Successfully created #{OrderItemAppointment.count} OrderItemAppointment records."
  end

  def self.create(
    order: Order.all.sample,
    appoint_to: nil,
    name: nil,
    description: Faker::Lorem.sentence,
    quantity: rand(1..5),
    unit_price: Faker::Commerce.price(range: 10..500.0),
    status: nil
  )
    raise "Cannot create an order item: No orders exist." if order.nil?
    company = order.company

    unless appoint_to
      products = company.products.to_a
      services = company.services.to_a
      appointable_items = products + services
      raise "Cannot create order item: Company '#{company.name}' has no products or services." if appointable_items.empty?
      appoint_to = appointable_items.sample
    end

    OrderItemAppointment.create!(
      order: order,
      appoint_to: appoint_to,
      name: name || "Order Item for #{appoint_to.class.name} ##{appoint_to.id}",
      description: description,
      quantity: quantity,
      unit_price: unit_price,
      status: status || OrderItemAppointment.statuses.keys.sample
    )
  end
end