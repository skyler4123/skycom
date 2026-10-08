# frozen_string_literal: true

# PermissionLog — immutable audit trail of every permission change.
# Written explicitly by Companies::PermissionsController after successful
# update/create (and future Policies CRUD via PermissionLogs::WriteService) —
# no callbacks. Snapshot columns are plain data (no validations); FKs exist
# only for filtering and are optional except company so logs survive deletes
# (parents use dependent: :nullify). tag_conditions before/after live in
# metadata as tag_conditions_before/tag_conditions_after.
class PermissionLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, { granted: 0, revoked: 1, conditions_changed: 2, resource_added: 3 }, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :policy, optional: true
  belongs_to :role, optional: true
  belongs_to :policy_role_appointment, optional: true
  belongs_to :employee, optional: true

  # --- Validations ---
  validates :action, presence: true
end
