# frozen_string_literal: true

# ImportLog — Atomic purpose: per-record audit row for one Import run.
#
# Why it exists: records exactly which record an import created so a later
# rollback can destroy only those rows and nothing else.
# How it works: written in batches by Imports::RunService alongside each
# successfully created record; Imports::RollbackService reads newest first and
# destroys the referenced records. Logs are kept as audit after a rollback.
# Main associations: belongs_to :import, :company (required);
# belongs_to :record, polymorphic: true.
class ImportLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, { created: 0 }, prefix: true

  # --- Associations ---
  belongs_to :import
  belongs_to :company
  belongs_to :record, polymorphic: true

  # --- Validations ---
  validates :action, presence: true
  validates :record_type, presence: true
  validates :record_id, presence: true
end
