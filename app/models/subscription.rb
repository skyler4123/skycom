class Subscription < ApplicationRecord
  # Assuming you use Discard for the 'discarded_at' column in migration
  # include Discard::Model

  # --- Associations ---
  belongs_to :subscription_group, optional: true
  belongs_to :price
  belongs_to :period
  belongs_to :seller, polymorphic: true
  belongs_to :buyer, polymorphic: true
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :processer, polymorphic: true, optional: true

  # --- Validations ---
  validates :plan_name, presence: true

  # Ensure the definition components are always present
  validates :price, :period, presence: true

  enum :country_code, COUNTRIE_CODES, prefix: true
  enum :plan_name, SUBSCRIPTION_ENUM_PLAN, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS
  enum :business_type, { b2b: 0, b2c: 1 }
end
