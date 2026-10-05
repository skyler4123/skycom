# frozen_string_literal: true

# AttendanceConfigLog — immutable audit trail of every AttendanceConfig change.
# Written explicitly by Companies::AttendanceConfigsController after successful
# create/update — no callbacks. Snapshot columns are plain data (no
# validations); FKs exist only for filtering and are optional except company
# so logs survive deletes (parent uses dependent: :nullify).
class AttendanceConfigLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, { created: 0, updated: 1 }, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :attendance_config, optional: true
  belongs_to :branch, optional: true
  belongs_to :employee, optional: true

  # --- Validations ---
  validates :action, presence: true
end
