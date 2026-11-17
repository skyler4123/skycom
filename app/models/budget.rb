# frozen_string_literal: true

# Budget — Atomic purpose: an approved spending ceiling for a scope (company, branch or cost center) over a set of periods.
#
# Why it exists: variance alerts need a stated expectation to compare against; without a stored budget every over-spend is invisible until the year closes. Keeping the ceiling per scope and period lets one company run department budgets while another runs a single company-wide budget.
# How it works: header row holds the scope and total; BudgetLines carry the per-account, per-month split that reports actually compare against. Approval reuses the existing Workflow machinery via `workflow_step`, never a bespoke status machine. Amounts are integer cents in the budget currency.
# Main associations: belongs_to :company, :branch (optional), :cost_center (optional), :fiscal_period (optional); has_many :budget_lines.
class Budget < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :budget_scope, BUDGET_SCOPES, prefix: true, default: :company

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :cost_center, optional: true
  belongs_to :fiscal_period, optional: true
  belongs_to :workflow_step, optional: true
  has_many :budget_lines, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :company_id }
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # --- Methods ---
  def planned_cents
    budget_lines.sum(:amount_cents)
  end
end
