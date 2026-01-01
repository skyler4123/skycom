class SubscriptionGroup < ApplicationRecord
  include TagConcern
  include ImmutableRecordConcern
  # Assuming you use Discard for the 'discarded_at' column in migration
  # include Discard::Model

  # --- Associations ---
  belongs_to :price
  belongs_to :period

  # A plan has many instances (appointments)
  has_many :subscription_group_appointments, dependent: :restrict_with_error

  # --- Validations ---
  validates :name, presence: true
  validates :code, uniqueness: true, allow_blank: true

  # Ensure the definition components are always present
  validates :price, :period, presence: true

  enum :country_code, COUNTRIE_CODES, prefix: true
  enum :plan_name, SUBSCRIPTION_ENUM_PLANS, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :timezone, TIMEZONES, prefix: true, prefix: true
  enum :business_type, { system_to_business: 0, business_to_business: 1, business_to_customer: 2 }, prefix: true
end
