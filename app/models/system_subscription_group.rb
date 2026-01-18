class SystemSubscriptionGroup < ApplicationRecord
  belongs_to :system_subscription_plan
  belongs_to :company_group
  belongs_to :company
  belongs_to :period
end
