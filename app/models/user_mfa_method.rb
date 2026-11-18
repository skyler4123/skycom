# frozen_string_literal: true

# UserMfaMethod — Atomic purpose: one second factor enrolled by one platform user (TOTP, passkey, SMS, email).
#
# Why it exists: a password alone cannot protect payroll and financial data, and MFA has to survive device loss: one row per method lets a user hold a passkey and a recovery code at once and lets the platform revoke a single compromised factor.
# How it works: system-level (belongs to User, not Company) because a user may access several companies. The shared secret is encrypted and never rendered. `confirmed_at` separates a scanned-but-unverified factor from a working one, and `last_used_at` supports risk decisions.
# Main associations: belongs_to :user.
class UserMfaMethod < ApplicationRecord
  # --- Enums ---
  enum :method, MFA_METHODS, prefix: true, default: :totp

  # --- Associations ---
  belongs_to :user

  # --- Scopes ---
  scope :active, -> { where(revoked_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  # --- Validations ---
  validates :method, presence: true

  # --- Methods ---
  def confirmed?
    confirmed_at.present? && revoked_at.nil?
  end
end
