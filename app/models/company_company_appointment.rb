# frozen_string_literal: true

# CompanyCompanyAppointment — Atomic purpose: a parent/child ownership link between two tenant companies for multi-entity consolidation.
#
# Why it exists: consolidated financials need an explicit ownership edge and percentage: which entities belong to the group, at what share, and whether the edge is consolidated. Deriving it from a shared owner user would break the moment one person owns two unrelated businesses.
# How it works: the only self-referencing pair that spans tenants, so it deliberately has NO company_id — the row lives above tenancy and SetDefaultCompanyConcern does not apply. Validations block self-links and cycles. `ownership_bp` is basis points (10000 = 100%) so partial ownership and minority interest stay expressible.
# Main associations: belongs_to :parent_company, :child_company (both Company); reads through Company#child_entities.
class CompanyCompanyAppointment < ApplicationRecord
  # --- Associations ---
  belongs_to :parent_company, class_name: "Company"
  belongs_to :child_company,  class_name: "Company"

  # --- Validations ---
  validates :ownership_bp, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10_000 }
  validates :child_company_id, uniqueness: { scope: :parent_company_id }
  validate :parent_differs_from_child
  validate :child_not_already_parent

  private

  def parent_differs_from_child
    return if parent_company_id.blank? || parent_company_id != child_company_id

    errors.add(:child_company, "cannot be the same company")
  end

  def child_not_already_parent
    return if parent_company_id.blank? || child_company_id.blank?
    return unless self.class.exists?(parent_company_id: child_company_id, child_company_id: parent_company_id)

    errors.add(:base, "ownership cycle between the two companies")
  end
end
