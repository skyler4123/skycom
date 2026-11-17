# frozen_string_literal: true

# WebhookEndpoint — Atomic purpose: one tenant-owned URL that receives outbound event payloads, with the events it subscribes to.
#
# Why it exists: every serious integration is event-driven: a client's own system needs to know when an invoice is paid or stock runs low, and polling the API is both slow and expensive. The endpoint, its secret and its subscriptions must be tenant-owned data.
# How it works: `event_keys` is a jsonb array drawn from a code-side registry so a typo cannot subscribe to an event that never fires. The signing secret is stored for HMAC verification; deliveries are separate rows so retries do not overwrite the payload that was actually sent.
# Main associations: belongs_to :company; has_many :webhook_deliveries.
class WebhookEndpoint < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  has_many :webhook_deliveries, dependent: :destroy

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :url, presence: true, length: { maximum: 2048 }

  # --- Methods ---
  def subscribed_to?(event_key)
    Array(event_keys).map(&:to_s).include?(event_key.to_s)
  end
end
