module Seed
  class SystemSubscriptionPlanService
    LIMITS = {
      temporary:     { employee: 3, company: 1, branch: 2, duration: 1.day },
      free:          { employee: 3, company: 1, branch: 2, duration: 30.days },
      basic:         { employee: 3, company: 1, branch: 2, duration: 30.days },
      basic_3m:      { employee: 3, company: 1, branch: 2, duration: 90.days },
      basic_6m:      { employee: 3, company: 1, branch: 2, duration: 180.days },
      basic_1y:      { employee: 3, company: 1, branch: 2, duration: 365.days },
      pro:           { employee: 3, company: 1, branch: 2, duration: 30.days },
      pro_3m:        { employee: 3, company: 1, branch: 2, duration: 90.days },
      pro_6m:        { employee: 3, company: 1, branch: 2, duration: 180.days },
      pro_1y:        { employee: 3, company: 1, branch: 2, duration: 365.days },
      enterprise:    { employee: 3, company: 1, branch: 2, duration: 30.days },
      enterprise_3m: { employee: 3, company: 1, branch: 2, duration: 90.days },
      enterprise_6m: { employee: 3, company: 1, branch: 2, duration: 180.days },
      enterprise_1y: { employee: 3, company: 1, branch: 2, duration: 365.days }
    }.freeze

    PRICING = {
      us: {
        temporary:     { amount: 0.00,    currency_code: :usd },
        free:          { amount: 0.00,    currency_code: :usd },
        basic:         { amount: 5.00,    currency_code: :usd },
        basic_3m:      { amount: 14.00,   currency_code: :usd },
        basic_6m:      { amount: 27.00,   currency_code: :usd },
        basic_1y:      { amount: 50.00,   currency_code: :usd },
        pro:           { amount: 29.99,   currency_code: :usd },
        pro_3m:        { amount: 85.00,   currency_code: :usd },
        pro_6m:        { amount: 170.00,  currency_code: :usd },
        pro_1y:        { amount: 325.00,  currency_code: :usd },
        enterprise:    { amount: 99.99,   currency_code: :usd },
        enterprise_3m: { amount: 285.00,  currency_code: :usd },
        enterprise_6m: { amount: 570.00,  currency_code: :usd },
        enterprise_1y: { amount: 1100.00, currency_code: :usd }
      },
      vn: {
        temporary:     { amount: 0.00,       currency_code: :vnd },
        free:          { amount: 0,          currency_code: :vnd },
        basic:         { amount: 250_000,    currency_code: :vnd },
        basic_3m:      { amount: 700_000,    currency_code: :vnd },
        basic_6m:      { amount: 1_350_000,  currency_code: :vnd },
        basic_1y:      { amount: 2_500_000,  currency_code: :vnd },
        pro:           { amount: 600_000,    currency_code: :vnd },
        pro_3m:        { amount: 1_700_000,  currency_code: :vnd },
        pro_6m:        { amount: 3_400_000,  currency_code: :vnd },
        pro_1y:        { amount: 6_500_000,  currency_code: :vnd },
        enterprise:    { amount: 2_000_000,  currency_code: :vnd },
        enterprise_3m: { amount: 5_700_000,  currency_code: :vnd },
        enterprise_6m: { amount: 11_000_000, currency_code: :vnd },
        enterprise_1y: { amount: 21_000_000, currency_code: :vnd }
      }
    }.freeze

    def self.seeding
      puts "🌱 Seeding System Subscription Plans with Price Appointments..."

      PRICING.each do |country_code, plans|
        plans.each do |plan_code, pricing_details|
          plan_config = LIMITS[plan_code]
          next unless plan_config

          # 1. Calculate Days
          total_days = (plan_config[:duration] / 1.day).to_i

          # 2. Find/Create the Plan record (The 'appoint_to')
          plan = SystemSubscriptionPlan.find_or_initialize_by(
            code: "#{country_code}_#{plan_code}",
            country_code: country_code
          )

          # Prepare dev-random statuses
          l_status = SystemSubscriptionPlan.lifecycle_statuses.keys.sample
          w_status = SystemSubscriptionPlan.workflow_statuses.keys.sample
          b_type = SystemSubscriptionPlan.business_types.keys.sample

          # 3. Update core attributes (Price is NOT included here)
          plan.update!(
            name: plan_code,
            description: "#{plan_code.to_s.humanize} plan for #{country_code.upcase}",
            duration_days: total_days,
            lifecycle_status: l_status,
            workflow_status: w_status,
            business_type: b_type,
            limits: plan_config,
            features: generate_features(plan_code)
          )

          # 4. ATTACH PRICE (This is where PriceConcern kicks in)
          # This creates a record in 'price_appointments' pointing to this plan
          plan.price = {
            amount: pricing_details[:amount],
            currency_code: pricing_details[:currency_code]
          }

          puts "   ✅ [#{plan.code}] price attached: #{plan.price.format}"
        end
      end

      puts "✅ Seeding Complete!"
    end

    private

    def self.generate_features(plan_code)
      {
        priority_support: plan_code.to_s.include?("enterprise"),
        custom_branding: !plan_code.to_s.include?("free") && !plan_code.to_s.include?("temporary"),
        api_access: plan_code.to_s.include?("pro") || plan_code.to_s.include?("enterprise")
      }
    end
  end
end
