# frozen_string_literal: true

# NotificationDelivery — Atomic purpose: one attempt to send one notification through one channel, with its result.
#
# Why it exists: external delivery fails in ways the app must survive: a Slack token expires, an email bounces. Without a delivery row the failure is invisible, the notification looks 'sent', and nobody knows the alert never arrived.
# How it works: immutable attempt log; retries create new rows so the failure history is preserved. `response_code`/`error_message` are the evidence, `attempts` counts the retry loop. Deliberately has no lifecycle/system fields — it is an event, not a business record.
# Main associations: belongs_to :company, :notification, :notification_channel.
class NotificationDelivery < ApplicationRecord
  # --- Enums ---
  enum :status, NOTIFICATION_DELIVERY_STATUSES, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :notification
  belongs_to :notification_channel

  # --- Scopes ---
  scope :failed, -> { where(status: [ :failed, :bounced ]) }
  scope :recent_first, -> { order(created_at: :desc) }
end
