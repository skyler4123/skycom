# frozen_string_literal: true

# SignatureRequest — Atomic purpose: an e-signature request sent for one document or stored file, tracking who must sign and when it expires.
#
# Why it exists: contracts, NDAs and offer letters are only useful if 'signed' is provable. A request row separates 'we asked for a signature' from 'the signature happened', so an expired or bounced request can be re-sent without losing the audit trail.
# How it works: attaches to exactly one subject (Document or StoredFile) — both are optional columns because the subject types differ, and a validation enforces exactly one. SignatureEvents hold the actual signatures. Status is an enum, never a boolean, so pending/expired/completed/declined stay distinguishable.
# Main associations: belongs_to :company, :document (optional), :stored_file (optional), :requested_by_employee (optional); has_many :signature_events.
class SignatureRequest < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, SIGNATURE_REQUEST_STATUSES, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :document, optional: true
  belongs_to :stored_file, optional: true
  belongs_to :requested_by_employee, class_name: "Employee", optional: true
  has_many :signature_events, dependent: :destroy

  # --- Scopes ---
  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
  scope :expired, -> { where(status: :expired) }

  # --- Validations ---
  validate :exactly_one_subject

  # --- Methods ---
  def expired_by_time?
    expires_at.present? && expires_at < Time.current && !status_completed?
  end

  private

  def exactly_one_subject
    return if document_id.present? ^ stored_file_id.present?

    errors.add(:base, "must reference exactly one document or stored file")
  end
end
