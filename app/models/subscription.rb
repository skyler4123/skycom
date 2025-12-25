# app/models/subscription.rb
class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :period
  belongs_to :price

  # --- 1. Plan Enum ---
  enum :plan_name, {
    free: 0,
    basic: 10,
    pro: 20,
    enterprise: 30
  }, prefix: true # usage: sub.plan_name_pro?

  # --- 2. Lifecycle Status (The Container) ---
  # Controls if the record is "Real" or "Trash/Hidden"
  enum :lifecycle_status, {
    initialized: 0,  # Being created, not ready yet
    live: 10,        # The standard active state
    suspended: 20,   # Admin paused it (fraud/ban)
    archived: 30     # Soft deleted / Historical record
  }, prefix: true # usage: sub.lifecycle_status_live?

  # --- 3. Workflow Status (The Journey) ---
  # Controls the financial/access logic
  enum :workflow_status, {
    pending_action: 0, # Waiting for payment info
    trialing: 10,      # Free trial
    active: 20,        # Paid and good
    past_due: 30,      # Payment failed, but in grace period
    cancelled: 40,     # User requested cancel (might still have access until end date)
    expired: 50        # Time runs out, access revoked
  }, prefix: true # usage: sub.workflow_status_active?

  # --- Validations ---
  validates :lifecycle_status, :workflow_status, :plan_name, presence: true
  validates :country_code, presence: true, length: { is: 2 }

  normalizes :country_code, with: -> { _1.strip.upcase }

  # --- Delegations (Shortcuts) ---
  delegate :amount, :currency, to: :price
  delegate :start_at, :end_at, :time_zone, to: :period

  scope :active_and_usable, -> {
    lifecycle_status_live
      .joins(:period)
      .where(
        "subscriptions.workflow_status IN (?) OR (subscriptions.workflow_status = ? AND (periods.end_at IS NULL OR periods.end_at > ?))",
        workflow_statuses.values_at(:trialing, :active, :past_due),
        workflow_statuses[:cancelled],
        Time.current
      )
  }

  # Clear the cache when a subscription changes so the user gets access immediately
  after_commit { Rails.cache.delete(["users", user_id, "active_subscription_status"]) }

  # --- The "Golden Rule" Access Check ---
  # Does the user actually get the features?
  def usable?
    # 1. System Check: Must be 'live' (not suspended or archived)
    # UPDATED: Was live_lifecycle_status? (suffix style)
    return false unless lifecycle_status_live?

    # 2. Business Check:
    # They get access if Active, Trialing, or even Past Due (Grace Period).
    # They ALSO get access if Cancelled, provided the Period hasn't ended yet.
    case workflow_status
    when "trialing", "active", "past_due"
      true
    when "cancelled"
      period_still_valid?
    else
      false # pending_action or expired
    end
  end

  private

  def period_still_valid?
    return true if end_at.nil? # Lifetime access
    Time.current < end_at
  end
end

# # We create it, but lifecycle is 'initialized' (0) because payment hasn't cleared.
# sub = Subscription.create!(
#   user: user,
#   period: some_period,
#   price: some_price,
#   plan_name: :pro,
#   lifecycle_status: :initialized,
#   workflow_status: :pending_action
# )
# # sub.usable? => false
