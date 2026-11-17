# frozen_string_literal: true

# IdentityProvider — Atomic purpose: one configured SSO provider (SAML or OIDC) a company's users can sign in through.
#
# Why it exists: enterprise buyers reject a product that only accepts a local password: their IT policy requires their identity provider to own access. The endpoint, client credentials and enforced flag must be stored per tenant so one company can enforce SSO without affecting another.
# How it works: company_id is nullable — nil means a platform-wide provider, a row overrides it for one tenant. `domains` decides which email domains are routed to it. Secrets live in an encrypted column, never in metadata, and are never serialised to the frontend (item 82).
# Main associations: belongs_to :company (optional).
class IdentityProvider < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :provider_type, IDENTITY_PROVIDER_TYPES, prefix: true, default: :saml

  # --- Associations ---
  belongs_to :company, optional: true

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }
  scope :enforced, -> { where(is_enforced: true) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  # --- Methods ---
  def matches_domain?(email)
    domain = email.to_s.split("@").last.to_s.downcase
    domain.present? && Array(domains).map(&:downcase).include?(domain)
  end
end
