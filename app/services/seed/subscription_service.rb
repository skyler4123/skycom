# This service seeds the database with Subscription records based on SUBSCRIPTION_PRICING_PLANS.

class Seed::SubscriptionService
  def self.run
    puts "Seeding Subscription records..."

    SUBSCRIPTION_PRICING_PLANS.each do |country, plans|
      plans.each do |plan_name, plan_details|
        amount = plan_details[:amount]
        currency = plan_details[:currency]

        # Create or find the price
        price = Price.find_or_create_by!(amount: amount, currency: currency)

        # Create a period for this subscription (assuming monthly)
        start_at = Time.current
        end_at = start_at + 1.month
        period = Period.find_or_create_by!(
          start_at: start_at,
          end_at: end_at,
          time_zone: 0 # UTC
        )

        # Create the subscription
        Subscription.find_or_create_by!(
          code: "#{plan_name.upcase}-#{country}",
          name: "#{plan_name.capitalize} Plan (#{country})",
          price: price,
          period: period,
          country_code: country
        )
      end
    end

    puts "Successfully created #{Subscription.count} Subscription records."
  end
end
