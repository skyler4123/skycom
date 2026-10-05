# frozen_string_literal: true

# TableConfigLog — immutable audit trail of every TableConfig change.
# Written explicitly by Companies::TableConfigsController after successful
# create/update — no callbacks. The metadata snapshot holds the raw columns
# array with no schema validation; FKs exist only for filtering and are
# optional except company so logs survive deletes (parent uses
# dependent: :nullify).
class TableConfigLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, { created: 0, updated: 1 }, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :table_config, optional: true
  belongs_to :category, optional: true
  belongs_to :property_mapping, optional: true
  belongs_to :employee, optional: true

  # --- Validations ---
  validates :action, presence: true
end
