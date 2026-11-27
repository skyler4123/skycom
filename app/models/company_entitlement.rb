# frozen_string_literal: true

# CompanyEntitlement — Atomic purpose: one module or capability switched on (or off) for one tenant, optionally with a limit and an expiry.
#
# Why it exists: a service agency should not see manufacturing and a retailer should not see field service; without per-tenant entitlements the only options are a fork or showing every module to everyone, which is what makes a demo feel unfinished.
# How it works: one row per (company, feature_key). Keys come from a code-side registry so a typo cannot invent a module. `limit_value` covers seat/record caps and `expires_at` covers trials, so a downgrade is a date change rather than a backfill.
# Main associations: belongs_to :company.
class CompanyEntitlement < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company

  # --- Scopes ---
  scope :enabled, -> { where(is_enabled: true) }
  scope :unexpired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  # --- Validations ---
  validates :feature_key, presence: true, length: { maximum: 64 }
  validates :feature_key, uniqueness: { scope: :company_id }

  # --- Methods ---
  def active?
    is_enabled? && (expires_at.nil? || expires_at > Time.current)
  end
end
