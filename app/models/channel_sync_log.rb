# frozen_string_literal: true

# ChannelSyncLog — Atomic purpose: one sync attempt between Skycom and an external channel, with its outcome.
#
# Why it exists: integrations fail silently by design: a webhook returns 200, the row never lands, and nobody notices until a customer complains. Recording each attempt with direction, resource and error text is what turns an invisible failure into a retryable one.
# How it works: append-only audit row; `direction` says push or pull, `resource` says orders/inventory/tracking, `payload` keeps the shape received. Retries create new rows so the failure history survives.
# Main associations: belongs_to :company, :channel_connection.
class ChannelSyncLog < ApplicationRecord
  # --- Enums ---
  enum :direction, SYNC_DIRECTIONS, prefix: true, default: :inbound
  enum :status, CHANNEL_SYNC_STATUSES, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :channel_connection

  # --- Scopes ---
  scope :recent_first, -> { order(created_at: :desc) }
  scope :failed, -> { where(status: :failed) }
end
