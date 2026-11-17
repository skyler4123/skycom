# frozen_string_literal: true

# WebhookDelivery — Atomic purpose: one attempt to deliver one event payload to one webhook endpoint.
#
# Why it exists: webhooks are retried, and a retry must send the same payload the client failed to receive, not whatever the record looks like later. Storing the payload at attempt time is what makes delivery idempotent and debuggable.
# How it works: immutable log with the frozen payload, attempt count and response. `status` moves pending → delivered → failed → exhausted so a client that was down for a week is visible instead of silently dropped. No lifecycle fields: this is evidence, not data under management.
# Main associations: belongs_to :company, :webhook_endpoint.
class WebhookDelivery < ApplicationRecord
  # --- Enums ---
  enum :status, WEBHOOK_DELIVERY_STATUSES, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :webhook_endpoint

  # --- Scopes ---
  scope :retryable, -> { where(status: [ :pending, :failed ]).where(attempts: ...11) }
  scope :recent_first, -> { order(created_at: :desc) }
end
