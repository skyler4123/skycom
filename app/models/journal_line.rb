# frozen_string_literal: true

# JournalLine — Atomic purpose: one debit or credit leg of a journal entry, optionally tagged with the dimensions reports are grouped by.
#
# Why it exists: the ledger is only useful if every line can be sliced by branch, department, cost center, customer, supplier, product and project without adding a column per report; keeping the dimensions on the line is what makes cost-center P&L, project margin and product profitability the same query.
# How it works: immutable. Exactly one of debit_cents / credit_cents is non-zero, enforced by validation. Amounts are integer cents in the entry's currency; `fx_rate` freezes the conversion rate at posting time so later rate changes never rewrite reported figures. No lifecycle/workflow columns: a ledger line is never soft-deleted or approved.
# Main associations: belongs_to :company, :journal_entry, :ledger_account and the optional dimensions :branch, :department, :cost_center, :employee, :customer, :supplier, :product, :project.
class JournalLine < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :journal_entry
  belongs_to :ledger_account
  belongs_to :branch, optional: true
  belongs_to :department, optional: true
  belongs_to :cost_center, optional: true
  belongs_to :employee, optional: true
  belongs_to :customer, optional: true
  belongs_to :supplier, optional: true
  belongs_to :product, optional: true
  belongs_to :project, optional: true

  # --- Validations ---
  validates :debit_cents, :credit_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :fx_rate, numericality: { greater_than: 0 }
  validate :exactly_one_side

  # --- Methods ---
  def signed_amount_cents
    debit_cents.to_i.positive? ? debit_cents.to_i : -credit_cents.to_i
  end

  private

  def exactly_one_side
    return if debit_cents.to_i.positive? ^ credit_cents.to_i.positive?

    errors.add(:base, "must debit or credit exactly one side")
  end
end
