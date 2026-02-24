class SystemSubscriptionPlan < ApplicationRecord
  belongs_to :price

  enum :country_code, COUNTRIE_CODES, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { b2c: 0, b2b: 1 }, prefix: true
end
