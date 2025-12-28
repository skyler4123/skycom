class Seed::SubscriptionService
  def self.create(user: nil)
    # 2. Determine Country and Plan
    # Prefer user's country, otherwise random from supported list
    country_code = user.country_code.presence || SUBSCRIPTION_PRICING_PLANS.keys.sample
    country_code = "US" unless SUBSCRIPTION_PRICING_PLANS.key?(country_code) # Fallback

    plan_name = Subscription.plan_names.keys.sample
    price_info = SUBSCRIPTION_PRICING_PLANS[country_code][plan_name.to_sym]

    # 3. Setup Price (Find or Create to avoid duplicates)
    price = Price.find_or_create_by!(
      amount: price_info[:amount],
      currency: price_info[:currency]
    )

    # 4. Setup Period (Current Month)
    # Using beginning_of_hour to ensure clean timestamps for finding existing records
    start_at = Time.current.beginning_of_hour
    end_at   = 1.month.from_now.beginning_of_hour

    period = Period.find_or_create_by!(
      start_at: start_at,
      end_at: end_at,
      time_zone: 0
    )

    # 5. Create Subscription
    Subscription.create!(
      user: user,
      period: period,
      price: price,
      plan_name: plan_name,
      lifecycle_status: :live,
      workflow_status: :active,
      country_code: country_code,
      auto_renew: [ true, false ].sample
    )
  end
end
