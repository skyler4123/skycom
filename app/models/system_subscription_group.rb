class SystemSubscriptionGroup < ApplicationRecord
  belongs_to :system_subscription_plan
  belongs_to :company_group
  belongs_to :branch, optional: true
  belongs_to :price
  belongs_to :period
  belongs_to :seller, polymorphic: true
  belongs_to :buyer, polymorphic: true
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :processer, polymorphic: true, optional: true
end
