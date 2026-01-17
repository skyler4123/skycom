class SubscriptionPlan < ApplicationRecord
  belongs_to :company_group
  belongs_to :company
  belongs_to :price
  belongs_to :period
end
