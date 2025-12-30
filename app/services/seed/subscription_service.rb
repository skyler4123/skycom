class Seed::SubscriptionService
  def self.run
    puts "Seeding Subscription records..."

    SUBSCRIPTION_PRICING_PLANS.each do |country_key, plans|
      plans.each do |tier_key, plan_details|
        
        # 1. Handle Price
        price = Price.find_or_create_by!(
          amount: plan_details[:amount], 
          currency: plan_details[:currency]
        )

        # 2. Handle Period
        # NOTE: Using Time.current in a seed means running this tomorrow will create NEW records.
        # To make it idempotent (repeatable), we anchor to the beginning of the current day and the ending of 1 month later.
        start_at = Time.current.beginning_of_day
        duration = plan_details[:duration] || 1.month
        end_at   = (start_at + duration).end_of_day

        period = Period.find_or_create_by!(
          start_at: start_at,
          end_at: end_at,
          time_zone: -12
        )

        # 3. Create or Update Subscription
        # We identify the subscription by Country and Tier.
        # If the Price or Period (duration) in the config changes, we update the record.
        subscription = Subscription.find_or_initialize_by(
          country_code: country_key, # Maps to enum :us, :vn
          tier: tier_key             # Maps to enum :free, :basic, etc.
        )
        
        subscription.price = price
        subscription.period = period
        subscription.save!

        puts "  -> Created/Found [#{country_key.upcase}] #{tier_key.to_s.humanize}: #{price.amount} #{price.currency}"
      end
    end

    puts "Done. Total Subscriptions: #{Subscription.count}"
  end
end