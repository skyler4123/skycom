class SubscriptionGroupAppointment < ApplicationRecord
  # include Discard::Model

  # --- Associations ---
  belongs_to :subscription

  # The Seller (System/Company)
  belongs_to :appoint_from, polymorphic: true
  # The Buyer (User/Customer)
  belongs_to :appoint_to, polymorphic: true
  # The Context (e.g. The specific Service or Product Group being subscribed to)
  belongs_to :appoint_for, polymorphic: true, optional: true
  # The Admin/System who created it
  belongs_to :appoint_by, polymorphic: true, optional: true

  # --- Delegations (Convenience) ---
  # Allows you to call `appointment.price` instead of `appointment.subscription.price`
  delegate :price, :period, :name, to: :subscription, allow_nil: true

  # --- Enums ---
  # These match the integer columns in your new migration
  enum :lifecycle_status, LIFECYCLE_STATUS, default: :active
  enum :workflow_status, WORKFLOW_STATUS, default: :draft

  # You might need specific business types for subscriptions (e.g. :recurring, :one_time)
  # or reuse your global constant.
  enum :business_type, {
    standard: 0,
    promotional: 1,
    trial: 2
  }, prefix: :type

  # --- Validations ---
  validates :appoint_from, :appoint_for, presence: true
  validates :lifecycle_status, presence: true

  # --- Scopes (Crucial for a stateless design) ---
  scope :active, -> { where(lifecycle_status: :active) }
  scope :auto_renewing, -> { where(auto_renew: true) }
  scope :expired, -> { where(lifecycle_status: :expired) }

  # --- Logic Helper ---
  def active?
    lifecycle_status == "active"
  end

  # Helper to calculate expiry based on the associated period definition
  def calculate_end_date
    # logic using self.period.duration
  end
end
