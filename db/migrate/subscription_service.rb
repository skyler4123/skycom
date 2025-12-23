class Seed::SubscriptionService
  def self.create(user: nil)
    # 1. Ensure we have a user to attach the subscription to
    user ||= User.order("RANDOM()").first

    unless user
      puts "⚠️ Skipping Subscription seed: No users available."
      return
    end

    # 2. Setup Price (Find or Create to avoid duplicates)
    # Using typical SaaS price points
    price = Price.find_or_create_by!(
      amount: [ 0.0, 9.99, 29.99, 99.99 ].sample,
      currency: 0 # Assuming 0 maps to USD/Default
    )

    # 3. Setup Period (Current Month)
    # Using beginning_of_hour to ensure clean timestamps for finding existing records
    start_at = Time.current.beginning_of_hour
    end_at   = 1.month.from_now.beginning_of_hour

    period = Period.find_or_create_by!(
      start_at: start_at,
      end_at: end_at,
      time_zone: 0
    )

    # 4. Create Subscription
    Subscription.create!(
      user: user,
      period: period,
      price: price,
      plan_name: Subscription.plan_names.keys.sample,
      lifecycle_status: :live,
      workflow_status: :active,
      country_code: Faker::Address.country_code,
      auto_renew: [ true, false ].sample
    )
  end
end