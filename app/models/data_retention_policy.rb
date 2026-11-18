# frozen_string_literal: true

# DataRetentionPolicy — Atomic purpose: one rule stating how long a resource's records are kept and what happens when the window ends.
#
# Why it exists: privacy law requires a stated retention period and evidence that it is applied; without a stored rule, deleting data is ad-hoc and irreversible, and 'we keep it because we need it' is not a defensible answer.
# How it works: rows per resource name with a day count and an action (anonymize, destroy, archive). The resource name is a code-validated key, not free text, so a typo cannot silently disable retention. The job reads these rows; nothing here deletes anything by itself.
# Main associations: belongs_to :company.
class DataRetentionPolicy < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, RETENTION_ACTIONS, prefix: true, default: :anonymize

  # --- Associations ---
  belongs_to :company

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :resource_name, presence: true, length: { maximum: 64 }
  validates :retention_days, numericality: { only_integer: true, greater_than: 0 }
  validates :resource_name, uniqueness: { scope: :company_id }

  # --- Methods ---
  def cutoff_date
    Date.current - retention_days.to_i.days
  end
end
