class SubscriptionGroup < ApplicationRecord
  belongs_to :price
  belongs_to :period
end
