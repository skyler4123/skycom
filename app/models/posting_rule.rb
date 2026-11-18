# frozen_string_literal: true

# PostingRule — Atomic purpose: maps a business event key (invoice.paid, stock.received, payroll.approved) to the debit and credit accounts it books to.
#
# Why it exists: the ledger must never hardcode 'sales books to 4000' — each company maps its own chart of accounts. Keeping the mapping in a table means adding a posting event is one row, not a code deploy, and closing the books does not require reading Ruby to find out where money went.
# How it works: one row per (company, event_key, priority); the first active rule whose jsonb conditions match the event payload wins. The event_key vocabulary itself lives in code (Ledger::Events registry) so a typo in the database cannot invent an event. This table is configuration — no journal lines reference it.
# Main associations: belongs_to :company, :debit_ledger_account, :credit_ledger_account (both LedgerAccount).
class PostingRule < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :debit_ledger_account,  class_name: "LedgerAccount"
  belongs_to :credit_ledger_account, class_name: "LedgerAccount"

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }
  scope :for_event, ->(key) { where(event_key: key) }
  scope :ordered, -> { order(:priority) }

  # --- Validations ---
  validates :event_key, presence: true, length: { maximum: 64 }
  validates :priority, numericality: { only_integer: true }
  validates :event_key, uniqueness: { scope: [ :company_id, :priority ] }
  validate :accounts_same_company

  private

  def accounts_same_company
    return if company_id.blank?

    [ debit_ledger_account, credit_ledger_account ].compact.each do |account|
      next if account.company_id == company_id

      errors.add(:base, "ledger accounts must belong to the same company")
      return
    end
  end
end
