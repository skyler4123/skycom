# frozen_string_literal: true

# SignatureEvent — Atomic purpose: one immutable record of a signature (or a decline/view) on a signature request.
#
# Why it exists: the legal value of an e-signature is the evidence around it: who signed, from which address, at what time, and with what signature hash. Those facts must be append-only — an event that can be edited proves nothing.
# How it works: inserted once per signer action and never updated. `signature_hash` fingerprints the signed payload so tampering with the underlying file is detectable. Deliberately has no lifecycle/workflow/system fields: an audit event is not a business record.
# Main associations: belongs_to :company, :signature_request.
class SignatureEvent < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :signature_request

  # --- Validations ---
  validates :signer_email, presence: true, length: { maximum: 255 }

  # --- Methods ---
  def signed?
    signed_at.present?
  end
end
