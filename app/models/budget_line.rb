# frozen_string_literal: true

# BudgetLine — Atomic purpose: one account's budgeted amount for one month inside a Budget.
#
# Why it exists: variance is only meaningful at account × month granularity: a yearly total hides that marketing overspent in Q1 while engineering underspent all year. Keeping the split as rows also lets the same budget roll up by cost center without recomputation.
# How it works: unique per (budget, account, month). `period_month` stores the first day of the month so range queries and grouping stay trivial. Amounts are integer cents and may be negative for credit/contra accounts.
# Main associations: belongs_to :company, :budget, :ledger_account.
class BudgetLine < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :budget
  belongs_to :ledger_account

  # --- Scopes ---
  scope :for_month, ->(month) { where(period_month: month.to_date.beginning_of_month) }

  # --- Validations ---
  validates :period_month, presence: true
  validates :amount_cents, numericality: { only_integer: true }
  validates :ledger_account_id, uniqueness: { scope: [ :budget_id, :period_month ] }
end
