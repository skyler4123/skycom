# frozen_string_literal: true

# Policy — Atomic purpose: one ABAC rule (resource + action + tag conditions) that
# grants or denies an action.
#
# Why it exists: permissions are data, not code; a Policy binds a resource and
# action to tag conditions, and roles collect policies to form a permission set
# (see docs/ABAC.md).
# How it works: belongs to company (touch) and optional branch; tag_conditions
# live in metadata; roles attach through PolicyRoleAppointment. Updating a policy
# touches its roles so employee permission caches invalidate, and every change is
# logged in PermissionLog.
# Main associations: belongs_to :company (touch), :branch (optional); has_many
# :roles through :policy_role_appointments; has_many :permission_logs
# (dependent: :nullify).
class Policy < ApplicationRecord
  store_accessor :metadata, :tag_conditions
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  # Using full path to avoid potential method clashes
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  # Policy business_types based on common organizational categories
  enum :business_type, {
    owner: 0,
    security: 1,
    regulatory: 2,
    operational: 3,
    compliance: 4
  }
  # --- Associations ---
  # REASON: If a global Policy definition (like its name or resource type) is edited, we touch the Company to invalidate any cached permission sets that include this policy.
  belongs_to :company, touch: true

  belongs_to :branch, optional: true

  has_many :policy_role_appointments, dependent: :destroy
  has_many :roles, through: :policy_role_appointments
  has_many :permission_logs, dependent: :nullify
  # --- Soft Deletion (Discard) ---
  # If you are using a gem like 'Discard' or similar for soft deletion:
  # include Discard::Model
  # default_scope -> { kept }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 150 }
  validates :resource, presence: true
  validates :action, presence: true

  # CRITICAL: Enforce uniqueness of the policy name scoped to the company.
  # This prevents two policies within the same company from having the same name.
  validates :name,
            uniqueness: {
              scope: :company_id,
              message: "A policy with this name already exists in this company."
            }

  # If you edit the Policy name/action/resource, notify the Roles.
  after_update :touch_roles

  private

  def touch_roles
    # We iterate and touch to trigger the Role's `after_touch` callback defined above.
    roles.each(&:touch)
  end
end
