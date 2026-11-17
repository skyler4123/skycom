# frozen_string_literal: true

# CostCenter — Atomic purpose: a reporting bucket that costs are attributed to, independent of the org chart.
#
# Why it exists: department-level P&L and budget variance need a dimension that survives reorganisations: departments are renamed and re-parented, but a cost center is an accounting label that must keep meaning across years. Without it every budget and every expense line has to change when the org changes.
# How it works: self-referencing tree (parent/children) with a company-unique code. Employees and journal lines point at it; budgets roll up through it. Managed as master data — no workflow, only an is_active flag so retired cost centers stay readable in history.
# Main associations: belongs_to :company, :parent (optional), :branch (optional), :manager_employee (optional); has_many :children, :employees, :journal_lines, :budgets.
class CostCenter < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :parent, class_name: "CostCenter", optional: true, inverse_of: :children
  belongs_to :branch, optional: true
  belongs_to :manager_employee, class_name: "Employee", optional: true
  has_many :children, class_name: "CostCenter", foreign_key: :parent_id, inverse_of: :parent, dependent: :restrict_with_error
  has_many :employees, dependent: :nullify
  has_many :journal_lines, dependent: :restrict_with_error
  has_many :budgets, dependent: :restrict_with_error

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:code) }

  # --- Validations ---
  validates :code, presence: true, length: { maximum: 32 }, uniqueness: { scope: :company_id }
  validates :name, presence: true, length: { maximum: 255 }
  validate :parent_not_self
  validate :parent_same_company

  private

  def parent_not_self
    return if parent_id.blank? || parent_id != id

    errors.add(:parent, "cannot be itself")
  end

  def parent_same_company
    return if parent.blank? || company_id.blank? || parent.company_id == company_id

    errors.add(:parent, "must belong to the same company")
  end
end
