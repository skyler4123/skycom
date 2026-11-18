# frozen_string_literal: true

# BrandProfile — Atomic purpose: one tenant's white-label identity: custom domain, logo and outbound sender.
#
# Why it exists: a reseller or franchise sells Skycom under its own name; without a stored brand, emails come from the wrong domain and the client sees the platform's logo on their invoices — the reason many deals fail at the last step.
# How it works: one active row per company and domain; `domain` is unique so a hostname cannot be claimed twice. Logos reuse StoredFile so uploads, permissions and CDN delivery are shared. Colours are tokens, never raw palette classes (docs/STYLING_GUIDELINES.md).
# Main associations: belongs_to :company, :logo_stored_file (optional).
class BrandProfile < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :logo_stored_file, class_name: "StoredFile", optional: true

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :domain, presence: true, length: { maximum: 255 }, uniqueness: true
end
