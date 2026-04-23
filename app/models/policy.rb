class Policy < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  # REASON: If a global Policy definition (like its name or resource type) is edited, we touch the Company to invalidate any cached permission sets that include this policy.
  belongs_to :company, touch: true

  belongs_to :branch, optional: true

  has_many :policy_appointments, dependent: :destroy
  has_many :roles, through: :policy_appointments, source: :appoint_to, source_type: "Role"

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments
  # --- Soft Deletion (Discard) ---
  # If you are using a gem like 'Discard' or similar for soft deletion:
  # include Discard::Model
  # default_scope -> { kept }

  # --- Enums ---
  # Using full path to avoid potential method clashes
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # Policy business_types based on common organizational categories
  enum :business_type, {
    security: 0,
    regulatory: 1,
    operational: 2,
    compliance: 3
  }

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
