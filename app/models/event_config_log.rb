# frozen_string_literal: true

# EventConfigLog — Atomic purpose: immutable audit trail of every EventConfig
# change.
#
# Why it exists: event rules control stock holds and order creation, so the log
# preserves who changed what and the before/after snapshot after the config is
# deleted.
# How it works: written explicitly by Companies::EventConfigsController after a
# successful create/update — no callbacks. Snapshot columns are plain data (no
# validations); FKs exist only for filtering and are optional except company
# (parent uses dependent: :nullify; denormalized *_name survives).
# Main associations: belongs_to :company (required); belongs_to :event_config,
# :category, :employee (optional).
class EventConfigLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, { created: 0, updated: 1 }, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :event_config, optional: true
  belongs_to :category, optional: true
  belongs_to :employee, optional: true

  # --- Validations ---
  validates :action, presence: true
end
