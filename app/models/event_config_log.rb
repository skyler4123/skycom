# frozen_string_literal: true

# EventConfigLog — immutable audit trail of every EventConfig change.
# Written explicitly by Companies::EventConfigsController after successful
# create/update — no callbacks. Snapshot columns are plain data (no
# validations); FKs to company/config/category/employee exist only for
# filtering and are all optional except company so logs survive deletes
# (parent uses dependent: :nullify, denormalized *_name survives).
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
