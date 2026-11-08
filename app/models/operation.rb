# frozen_string_literal: true

# Operation — Atomic purpose: one deployable operation definition for a company.
#
# Why it exists: operation screens are keyed by purpose (POS, Booking,
# Inventory, …), not by industry or target role. Every company receives the full
# catalog and enables the operations it uses per branch or warehouse.
# How it works: an Operation is company-level and uniquely identified by
# (company, operation_type). Location connections live in
# BranchOperationAppointment / OperationWarehouseAppointment; appointment metadata
# overrides this Operation's metadata to produce the effective config. Saving this
# Operation's metadata resets every appointment to a copy of it.
# Main associations: belongs_to :company; has_many :branch_operation_appointments /
# :operation_warehouse_appointments (and branches/warehouses through them).
class Operation < ApplicationRecord
  include OperationPageCacheConcern

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
    store_manager: 700
  }, prefix: true
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
  validates :operation_type, presence: true, uniqueness: { scope: :company_id }
  validate :metadata_must_be_a_hash
  validate :roles_metadata_must_be_strings

  # --- Callbacks ---
  after_update :copy_metadata_to_appointments, if: :saved_change_to_metadata?

  # Effective config for one appointment. Appointment metadata wins, except roles
  # which are always constrained to the operation roles.
  def config_for(appointment)
    config = (metadata || {}).deep_merge(appointment.metadata || {})
    return config unless metadata&.key?("roles") || appointment.metadata&.key?("roles")

    config["roles"] = effective_roles(appointment)
    config
  end

  # Local roles may narrow access but never widen it. Empty local roles inherit
  # the operation roles.
  def effective_roles(appointment = nil)
    operation_roles = metadata_roles(metadata)
    return operation_roles if appointment.nil?

    local_roles = metadata_roles(appointment.metadata)
    return operation_roles if local_roles.empty?
    return local_roles if operation_roles.empty?

    local_roles & operation_roles
  end

  # Empty/missing roles means every employee with Operation read can access it.
  # An appointment with local roles can narrow that set, never widen it.
  def accessible_by?(employee, appointment: nil)
    return true if employee.owner_role?

    local_roles = appointment && metadata_roles(appointment.metadata)
    allowed = effective_roles(appointment)
    return false if allowed.empty? && local_roles.present?
    return true if allowed.empty?

    employee.roles.where(name: allowed).exists?
  end

  # Fast role check for already-serialized appointments (cached index rows).
  def self.roles_allow_access?(roles:, employee:, role_names: nil)
    return true if employee.owner_role?

    allowed = Array(roles).map(&:to_s)
    return true if allowed.empty?

    names = role_names || employee.roles.pluck(:name)
    (names.map(&:to_s) & allowed).any?
  end

  private

  def copy_metadata_to_appointments
    attributes = { metadata: metadata, updated_at: Time.current }
    branch_operation_appointments.update_all(attributes)
    operation_warehouse_appointments.update_all(attributes)
  end

  def metadata_roles(source)
    return [] unless source.is_a?(Hash)

    roles = source["roles"]
    roles.is_a?(Array) ? roles.map(&:to_s) : []
  end

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
