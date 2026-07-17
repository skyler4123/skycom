class SubscriptionPlanAppointment < ApplicationRecord
  include TagConcern
  include SetDefaultCompanyConcern


  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :subscription_plan
  belongs_to :subscription_group, optional: true
  belongs_to :seller, polymorphic: true
  belongs_to :buyer, polymorphic: true
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :processer, polymorphic: true, optional: true

  enum :country_code, COUNTRY_CODES, prefix: true, default: :us
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :business_type, { system_to_business: 0, business_to_business: 1, business_to_customer: 2 }, prefix: true
end
