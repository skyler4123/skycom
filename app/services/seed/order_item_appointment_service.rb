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
end