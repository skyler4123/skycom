# frozen_string_literal: true

# NetworkPolicy — Atomic purpose: one IP range allowed to reach a sensitive area of the product (all, finance, HR, admin).
#
# Why it exists: payroll and bank data are the highest-value records a tenant holds; letting them be opened from any network makes credential theft catastrophic. A CIDR list per scope is the minimum control an auditor asks for.
# How it works: rows of CIDR blocks with a scope, so an office range can be allowed for finance without loosening the rest. `is_active` disables a rule without deleting the audit of what was once allowed. Whether the current request matches is a service concern, not a column.
# Main associations: belongs_to :company.
class NetworkPolicy < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :scope, NETWORK_POLICY_SCOPES, prefix: true, default: :all

  # --- Associations ---
  belongs_to :company

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }
  scope :for_scope, ->(scope) { where(scope: [ :all, scope ]) }

  # --- Validations ---
  validates :cidr, presence: true, length: { maximum: 64 }
  validate :cidr_is_parseable

  private

  def cidr_is_parseable
    IPAddr.new(cidr.to_s)
  rescue IPAddr::Error, ArgumentError
    errors.add(:cidr, "must be a valid IP address or CIDR block")
  end
end
