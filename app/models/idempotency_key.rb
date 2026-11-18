# frozen_string_literal: true

# IdempotencyKey — Atomic purpose: stores the response produced for one client-supplied request key so a retry returns the original result instead of repeating the side effect.
#
# Why it exists: offline-first clients and flaky networks retry; a retried checkout that creates a second invoice is a real financial loss. The key must be persisted server-side because the retry may arrive at a different process minutes later.
# How it works: unique per (company, key). The stored response is replayed verbatim to the retry. `expires_at` bounds growth — after the window a key is treated as new. No lifecycle/system fields: the row is a request memo, not a business entity.
# Main associations: belongs_to :company.
class IdempotencyKey < ApplicationRecord
  # --- Associations ---
  belongs_to :company

  # --- Scopes ---
  scope :unexpired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  # --- Validations ---
  validates :key, presence: true, length: { maximum: 255 }
  validates :key, uniqueness: { scope: :company_id }
end
