# frozen_string_literal: true

# PermissionLog — Atomic purpose: immutable audit trail of every permission
# change.
#
# Why it exists: ABAC grants and tag conditions are security-sensitive; the log
# preserves the before/after conditions and who made the change after the related
# rows are deleted.
# How it works: written explicitly by Companies::PermissionsController after a
# successful update/create (and Policies CRUD via PermissionLogs::WriteService) —
# no callbacks. Snapshot columns are plain data; FKs are optional except company
# (parents use dependent: :nullify); tag_conditions before/after live in metadata
# as tag_conditions_before/tag_conditions_after.
# Main associations: belongs_to :company (required); belongs_to :policy, :role,
# :policy_role_appointment, :employee (optional).
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
