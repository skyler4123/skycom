# frozen_string_literal: true

# TableConfigLog — Atomic purpose: immutable audit trail of every TableConfig
# change.
#
# Why it exists: table layouts are tenant configuration; the log preserves who
# changed which resource and the raw columns snapshot after the config row is
# deleted.
# How it works: written explicitly by Companies::TableConfigsController after a
# successful create/update — no callbacks. The metadata snapshot holds the raw
# columns array with no schema validation; FKs exist only for filtering and are
# optional except company (parent uses dependent: :nullify).
# Main associations: belongs_to :company (required); belongs_to :table_config,
# :category, :property_mapping, :employee (optional).
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
