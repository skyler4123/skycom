class SubscriptionPlan < ApplicationRecord
  has_many :subscriptions, dependent: :destroy

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :price
end
