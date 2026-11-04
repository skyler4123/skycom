# frozen_string_literal: true

# Operation — Atomic purpose: one deployable operation definition for a company.
#
# Why it exists: operation screens are keyed by purpose (POS, Booking,
# Inventory, …), not by industry or target role. Every company receives the full
# catalog and enables the operations it uses per branch or warehouse.
# How it works: an Operation is company-level and uniquely identified by
# (company, operation_type, resolution). Location connections live in
# BranchOperationAppointment / OperationWarehouseAppointment; the appointment metadata is
# deep-merged with this Operation's metadata (Operation wins) to produce the effective
# config.
# Main associations: belongs_to :company; has_many :branch_operation_appointments /
# :operation_warehouse_appointments (and branches/warehouses through them).
class Operation < ApplicationRecord
  # --- Attributes ---
  attribute :permission_resource_name, :string, default: "Operation"

  # --- Enums ---
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :operation_type, {
    pos: 100,
    booking: 200,
    inventory: 300,
    reception: 400,
    kitchen: 500,
    housekeeping: 600,
    store_manager: 700
  }, prefix: true
  enum :resolution, { mobile: 10, desktop: 20 }, prefix: true, default: :desktop
  enum :lifecycle_status, { active: 10, draft: 20, archived: 30 }, prefix: true, default: :draft
  enum :workflow_status, { pending_review: 10, approved: 20, deployed: 30 }, prefix: true, default: :pending_review

  # --- Associations ---
  belongs_to :company
  has_many :branch_operation_appointments, dependent: :destroy
  has_many :branches, through: :branch_operation_appointments
  has_many :operation_warehouse_appointments, dependent: :destroy
  has_many :warehouses, through: :operation_warehouse_appointments

  # --- Validations ---
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :operation_type, presence: true, uniqueness: { scope: %i[company_id resolution] }
  validates :resolution, presence: true
  validate :metadata_must_be_a_hash
  validate :roles_metadata_must_be_strings

  # Effective config for one appointment. Operation metadata wins on every conflict.
  def config_for(appointment)
    (appointment.metadata || {}).deep_merge(metadata || {})
  end

  # Empty/missing roles means every employee with Operation read can access it.
  def accessible_by?(employee)
    return true if employee.owner_role?

    allowed = Array(metadata.is_a?(Hash) ? metadata["roles"] : nil).map(&:to_s)
    return true if allowed.empty?

    employee.roles.where(name: allowed).exists?
  end

  private

  def metadata_must_be_a_hash
    if metadata.nil?
      errors.add(:metadata, :blank)
      return
    end
    return if metadata.is_a?(Hash)

    errors.add(:metadata, "must be a hash")
  end

  def roles_metadata_must_be_strings
    return unless metadata.is_a?(Hash)
    return unless metadata.key?("roles")

    roles = metadata["roles"]
    return if roles.is_a?(Array) && roles.all? { |role| role.is_a?(String) }

    errors.add(:metadata, "roles must be an array of strings")
  end
end
