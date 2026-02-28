class SubscriptionGroup < ApplicationRecord
  include TagConcern
  include ImmutableRecordConcern
  # Assuming you use Discard for the 'discarded_at' column in migration
  # include Discard::Model

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :price
  belongs_to :period
  belongs_to :seller, polymorphic: true
  belongs_to :buyer, polymorphic: true
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :processer, polymorphic: true, optional: true

  # A plan has many instances (appointments)
  has_many :subscription_group_appointments, dependent: :restrict_with_error

  # --- Validations ---
  validates :name, presence: true
  validates :code, uniqueness: true, allow_blank: true

  # Ensure the definition components are always present
  validates :price, :period, presence: true

  enum :country_code, COUNTRIE_CODES, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :timezone, TIMEZONES, prefix: true
  enum :business_type, { system_to_business: 0, business_to_business: 1, business_to_customer: 2 }, prefix: true
end
