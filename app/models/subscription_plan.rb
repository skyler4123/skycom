class SubscriptionPlan < ApplicationRecord
  has_many :subscriptions, dependent: :destroy

  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :price
end
