# frozen_string_literal: true

# ChannelConnection — Atomic purpose: one configured connection to an external sales channel (Shopify, WooCommerce, Amazon, Shopee).
#
# Why it exists: marketplace sync needs a place to keep credentials, status and the last successful sync per channel; spreading that across settings rows or environment variables makes a per-tenant integration impossible and leaks one tenant's token into another's.
# How it works: credentials are stored in an encrypted jsonb column, never in metadata. Status tracks connected/error/disabled so a broken token is visible instead of silent. Sync evidence lives in ChannelSyncLogs, not here.
# Main associations: belongs_to :company; has_many :channel_sync_logs.
class ChannelConnection < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :channel, CHANNEL_KINDS, prefix: true, default: :shopify

  # --- Associations ---
  belongs_to :company
  has_many :channel_sync_logs, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
end
