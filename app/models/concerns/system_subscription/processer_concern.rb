module SystemSubscription::ProcesserConcern
  extend ActiveSupport::Concern

  included do
    has_many :system_subscriptions, as: :processer, dependent: :destroy
  end
end
