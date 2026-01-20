class SystemSubscriptionPlan < ApplicationRecord
  belongs_to :price
  enum :country_code, COUNTRIE_CODES, prefix: true

end
