class Subscription < ApplicationRecord
  belongs_to :subscription_group
  belongs_to :company_group
  belongs_to :company
end
