module Subscription::BuyerConcern
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :buyer, dependent: :destroy
  end
end
