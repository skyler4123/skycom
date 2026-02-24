module SystemSubscription::BuyerConcern
  extend ActiveSupport::Concern

  included do
    has_many :system_subscriptions, as: :buyer, dependent: :destroy
  end
end
