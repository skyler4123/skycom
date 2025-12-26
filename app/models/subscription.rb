class Subscription < ApplicationRecord
  belongs_to :subscription_group
  belongs_to :price
  belongs_to :period
end
