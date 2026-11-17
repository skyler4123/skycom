# frozen_string_literal: true

# CommissionPlan — Atomic purpose: the rules for how a salesperson earns commission (basis, scope, validity).
#
# Why it exists: commission must be recomputable and explainable: if the rule lives in a spreadsheet, two people disagree about what was owed. A plan row names the basis (revenue, margin or cash collected) and the scope it applies to, so a payslip can point at the exact plan used.
# How it works: tiers live in CommissionTiers so brackets are rows. Scope by category or employee group rather than per employee, so a team restructure does not rewrite history. Effective dates freeze past calculations.
# Main associations: belongs_to :company, :applies_to_category (optional), :applies_to_employee_group (optional); has_many :commission_tiers, :commission_entries.
class CommissionPlan < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :basis, COMMISSION_BASES, prefix: true, default: :revenue

  # --- Associations ---
  belongs_to :company
  belongs_to :applies_to_category, class_name: "Category", optional: true
  belongs_to :applies_to_employee_group, class_name: "EmployeeGroup", optional: true
  has_many :commission_tiers, dependent: :destroy
  has_many :commission_entries, dependent: :restrict_with_error

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :company_id }
end
