# frozen_string_literal: true

# NotificationChannel — Atomic purpose: one configured delivery destination (email, Slack, Teams, Zalo, WhatsApp, push) for a tenant.
#
# Why it exists: in-app notifications only help people already looking at the screen; a manager who needs to know a stock-out happened needs it on their phone. The webhook URL or token per channel has to be stored per tenant, encrypted, and switchable.
# How it works: one row per channel per company; `config` holds the destination and is encrypted at the application level. Deliveries are NotificationDeliveries so a failed send is retried and evidenced rather than lost.
# Main associations: belongs_to :company; has_many :notification_deliveries.
class NotificationChannel < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :channel, NOTIFICATION_CHANNEL_KINDS, prefix: true, default: :email

  # --- Associations ---
  belongs_to :company
  has_many :notification_deliveries, dependent: :destroy

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :channel, uniqueness: { scope: :company_id }
end
