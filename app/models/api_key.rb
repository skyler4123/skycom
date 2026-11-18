# frozen_string_literal: true

# ApiKey — Atomic purpose: one scoped credential a tenant's developers use to call the public REST API.
#
# Why it exists: an API cannot run on a user session cookie: integrations are server-to-server, need their own revocation and must not inherit a person's permissions. A key row with scopes is the smallest thing that is both usable and revocable.
# How it works: only the digest of the token is stored — the plaintext is shown once at creation and never persisted, so a database leak does not leak working keys. `scopes` limits what the key may do; `revoked_at` kills it without deleting the audit trail. System fields are omitted on purpose: a key is config, not soft-deletable data.
# Main associations: belongs_to :company, :created_by_employee (optional).
class ApiKey < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :created_by_employee, class_name: "Employee", optional: true

  # --- Scopes ---
  scope :active, -> { where(revoked_at: nil) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :token_digest, presence: true, uniqueness: true

  # --- Methods ---
  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end
end
