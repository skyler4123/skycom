# frozen_string_literal: true

# PageWarehouseAppointment — Atomic purpose: binds one company Page to one
# Warehouse.
#
# Why it exists: warehouse-scoped operation pages (currently Inventory) need the
# same deployable-page contract as branch pages without putting a warehouse_id
# on the Page itself.
# How it works: company_id derives from the page via SetDefaultCompanyConcern.
# Page config overrides this row's metadata when effective config is built.
# Main associations: belongs_to :company, :page, :warehouse.
class PageWarehouseAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  # --- Attributes ---
  attribute :metadata, default: -> { {} }
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, { inactive: 0, active: 1 }, prefix: true, default: :active

  # --- Associations ---
  belongs_to :company
  belongs_to :page
  belongs_to :warehouse

  # --- Scopes ---
  scope :active, -> { where(workflow_status: :active) }

  # --- Validations ---
  validates :page_id, uniqueness: { scope: %i[company_id warehouse_id] }
  validate :page_must_belong_to_company
  validate :warehouse_must_belong_to_company
  validate :metadata_must_be_a_hash

  private

  def page_must_belong_to_company
    return if page.blank? || company_id.blank?
    return if page.company_id == company_id

    errors.add(:page, "does not belong to this company")
  end

  def warehouse_must_belong_to_company
    return if warehouse.blank? || company_id.blank?
    return if warehouse.company_id == company_id

    errors.add(:warehouse, "does not belong to this company")
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
