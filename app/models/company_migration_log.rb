# frozen_string_literal: true

# CompanyMigrationLog — Atomic purpose: per-record audit row for one
# CompanyMigration action.
#
# Why it exists: records exactly what the import created or updated and which
# polymorphic record it touched, so a migration can be inspected and its effects
# traced (see docs/DATA_MIGRATION.md).
# How it works: written by the data-migration engine alongside each processed row;
# action is created/updated and the polymorphic `record` points at the affected
# domain row.
# Main associations: belongs_to :company_migration, :company (required);
# belongs_to :record, polymorphic: true.
class CompanyMigrationLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, { created: 0, updated: 1 }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { general: 0 }, prefix: true

  # --- Associations ---
  belongs_to :company_migration
  belongs_to :company
  belongs_to :record, polymorphic: true

  # --- Validations ---
  validates :action, presence: true
end
