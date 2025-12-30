module SubscriptionSellerConcern
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :seller, dependent: :destroy
  end
end
