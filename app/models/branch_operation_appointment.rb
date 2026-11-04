# frozen_string_literal: true

# BranchOperationAppointment — Atomic purpose: binds one company Operation to one Branch.
#
# Why it exists: an Operation is a company-level purpose definition; branches opt into
# the operations they deploy, with branch-specific metadata and an
# active/inactive switch.
# How it works: company_id derives from the branch via SetDefaultCompanyConcern.
# This row's metadata overrides the Operation metadata when effective config is
# built; local roles may narrow operation roles but never widen them.
# Main associations: belongs_to :company, :branch, :operation.
class BranchOperationAppointment < ApplicationRecord
  include SetDefaultCompanyConcern
  include OperationPageCacheConcern

  # --- Attributes ---
  attribute :metadata, default: -> { {} }
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, { inactive: 0, active: 1 }, prefix: true, default: :active

  # --- Associations ---
  belongs_to :company
  belongs_to :branch
  belongs_to :operation

  # --- Scopes ---
  scope :active, -> { where(workflow_status: :active) }

  # --- Validations ---
  validates :operation_id, uniqueness: { scope: %i[company_id branch_id] }
  validate :branch_must_belong_to_company
  validate :operation_must_belong_to_company
  validate :metadata_must_be_a_hash
  validate :roles_metadata_must_be_within_company_and_operation, on: :update

  private

  def roles_metadata_must_be_within_company_and_operation
    return unless metadata.is_a?(Hash) && metadata.key?("roles")

    roles = metadata["roles"]
    unless roles.is_a?(Array) && roles.all? { |role| role.is_a?(String) }
      errors.add(:metadata, "roles must be an array of strings")
      return
    end
    return if roles.empty?

    company_roles = company&.roles&.pluck(:name) || []
    if (roles - company_roles).any?
      errors.add(:metadata, "roles must be company roles")
      return
    end

    operation_roles = Array(operation&.metadata&.[]("roles")).map(&:to_s)
    errors.add(:metadata, "roles must be included in the operation roles") if operation_roles.any? && (roles - operation_roles).any?
  end

  def branch_must_belong_to_company
    return if branch.blank? || company_id.blank?
    return if branch.company_id == company_id

    errors.add(:branch, "does not belong to this company")
  end

  def operation_must_belong_to_company
    return if operation.blank? || company_id.blank?
    return if operation.company_id == company_id

    errors.add(:operation, "does not belong to this company")
  end

  def metadata_must_be_a_hash
    if metadata.nil?
      errors.add(:metadata, :blank)
      return
    end
    return if metadata.is_a?(Hash)

    errors.add(:metadata, "must be a hash")
  end
end
