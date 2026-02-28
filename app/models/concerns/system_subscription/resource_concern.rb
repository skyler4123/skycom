module SystemSubscription::ResourceConcern
  extend ActiveSupport::Concern

  included do
    has_many :system_subscriptions, as: :resource, dependent: :destroy

    def system_subscribe!(
      plan_name:,
      country_code: self.country_code || :us,
      seller: System.find_by(name: "System"),
      buyer: self.company,
      resource: self,
      processer: System.find_by(name: "System"),
      lifecycle_status: :active,
      workflow_status: :pending,
      renew: false
    )
      system_subscription_plan = SystemSubscriptionPlan.find_by!(name: plan_name, country_code: country_code)
      period = Seed::PeriodService.create(
        start_at: Time.current.beginning_of_day,
        end_at: Time.current.end_of_day + system_subscription_plan.duration_days.days,
        timezone: -12
      )
      SystemSubscription.create!(
        company: self.company,
        system_subscription_plan: system_subscription_plan,
        seller: seller,
        buyer: buyer,
        resource: resource,
        processer: processer,
        country_code: country_code,
        price: system_subscription_plan.price,
        period: period,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status
      )
    end

    def system_subscribe_temporary!(country_code: :us)
      subscribe!(plan_name: :temporary, country_code: country_code)
    end

    def system_subscribe_free!(country_code: :us)
      subscribe!(plan_name: :free, country_code: country_code)
    end

    # A flexible method to subscribe to any plan_name.
    # Example: user.subscribe_to(plan_name: :basic_6m, country_code: :us)
    def system_subscribe_to(plan_name:, country_code: :us, renew: false)
      subscribe!(plan_name: plan_name, country_code: country_code)
    end

    def system_unsubscribe!
      latest_subscription&.update!(lifecycle_status: :inactive, workflow_status: :cancelled)
    end

    def system_unrenew!
      latest_subscription&.update!(renew: false)
    end

    def latest_system_subscription
      subscriptions.order(created_at: :desc).first
    end
  end
end
