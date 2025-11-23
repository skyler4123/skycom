# This service seeds the database with Order records. Each order is associated
# with a Company and a Customer from that same company. It uses enums from the
# Order model and simulates soft deletion for a portion of the records.

class Seed::OrderService

  # Configuration for the number of orders to create per company
  ORDERS_PER_COMPANY = 5

  def self.run
    # Get enum keys once before the loop for efficiency.
    statuses = Order.statuses.keys
    business_types = Order.business_types.keys

    puts "Seeding Order records..."

    Company.all.each do |company|
      # Get customers for the current company. Skip if there are none.
      customer_ids = company.customer_ids
      next if customer_ids.empty?

      ORDERS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Order.create!(
          company: company,
          customer_id: customer_ids.sample,
          name: "Order ##{company.id}-#{i + 1}",
          description: Faker::Lorem.sentence(word_count: 15),
          currency: Faker::Currency.code,
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Order.count} Order records."
  end

  def self.create(
    company:,
    customer: nil,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 15),
    currency: Faker::Currency.code,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    customer ||= company.customers.sample
    raise "Cannot create an order: Company '#{company.name}' has no customers." if customer.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Order.create!(
      company: company,
      customer: customer,
      name: name || "Order for #{customer.name}",
      description: description,
      currency: currency,
      status: status || Order.statuses.keys.sample,
      business_type: business_type || Order.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end