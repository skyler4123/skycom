module SubscriptionProcesserConcern
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :processer, dependent: :destroy
  end
end
