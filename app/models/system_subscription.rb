class SystemSubscription < ApplicationRecord
  belongs_to :system_subscription_plan
  belongs_to :subscription_group
  belongs_to :company_group
  belongs_to :company
  belongs_to :price
  belongs_to :period
end
