module SubscriptionBuyerConcern
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :buyer, dependent: :destroy

    def subscribe(
      tier:,
      seller: System.find_by(name: "System"),
      buyer: self,
      resource: nil,
      processer: System.find_by(name: "System"),
      name: nil,
      country_code: :us,
      lifecycle_status: :active,
      workflow_status: :pending,
      renew: false
      )
      name ||= tier.to_s.humanize
      plan = SUBSCRIPTION_PRICING_PLANS.dig(country_code.to_sym, tier.to_sym)
      return unless plan

      price = Price.find_or_create_by!(
        amount: plan[:amount],
        currency: plan[:currency]
      )

      period = Period.find_or_create_by!(
        start_at: Time.current.beginning_of_day,
        end_at: Time.current.end_of_day + (plan[:duration] || 1.month),
        time_zone: -12
      )

      subscriptions.create!(
        seller: seller,
        buyer: buyer,
        resource: resource,
        processer: processer,
        name: name,
        tier: tier,
        country_code: country_code,
        price: price,
        period: period,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status
      )
    end

    def subscribe_temporary(country_code: :us)
      subscribe(tier: :temporary, country_code: country_code)
    end

    def subscribe_free(country_code: :us)
      subscribe(tier: :free, country_code: country_code)
    end

    # A flexible method to subscribe to any tier.
    # Example: user.subscribe_to(tier: :basic_6m, country_code: :us)
    def subscribe_to(tier:, country_code: :us, renew: false)
      subscribe(tier: tier, country_code: country_code)
    end

    def unsubscribe
      latest_subscription&.update(lifecycle_status: :inactive, workflow_status: :cancelled)
    end

    def unrenew
      # latest_subscription&.update(renew: false)
    end

    def latest_subscription
      subscriptions.order(created_at: :desc).first
    end
  end
end
