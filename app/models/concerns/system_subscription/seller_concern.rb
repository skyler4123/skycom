module SystemSubscription::SellerConcern
  extend ActiveSupport::Concern

  included do
    has_many :system_subscriptions, as: :seller, dependent: :destroy
  end
end
