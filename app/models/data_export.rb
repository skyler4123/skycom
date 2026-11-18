# frozen_string_literal: true

# DataExport — Atomic purpose: one request to export a tenant's data (or a slice of it) into a downloadable archive.
#
# Why it exists: self-service export is both a contract lever and a lock-in antidote: a client who knows they can leave is more willing to join. It is also the only practical answer to 'give me everything you hold about us'.
# How it works: a request row with the requested slice, a status and the produced StoredFile, so the heavy work runs in a job and the result is downloadable through the existing storage path. `error_message` keeps a failed export visible instead of leaving it queued forever.
# Main associations: belongs_to :company, :requested_by_employee (optional), :stored_file (optional).
class DataExport < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, DATA_EXPORT_STATUSES, prefix: true, default: :queued

  # --- Associations ---
  belongs_to :company
  belongs_to :requested_by_employee, class_name: "Employee", optional: true
  belongs_to :stored_file, optional: true

  # --- Scopes ---
  scope :completed, -> { where(status: :completed) }
  scope :recent_first, -> { order(created_at: :desc) }
end
