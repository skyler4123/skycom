# frozen_string_literal: true

# JournalEntry — Atomic purpose: the header of one balanced accounting transaction (a bundle of journal lines) produced by a business event.
#
# Why it exists: every money-moving event — an invoice paid, stock received, payroll approved, depreciation posted — must leave an auditable double-entry trail that is written once and never edited; storing the source reference and event key here is what makes posting idempotent and lets any report trace a number back to the document that produced it.
# How it works: immutable after posting. The unique index on (company, source, event_key) is the idempotency guard: a retried job or replayed request inserts nothing. `source_type`/`source_id` is polymorphic on purpose — the same precedent as StockTransaction#appoint_for and WorkflowStepLog#subject — because the set of posting sources grows with every module. Balances live on JournalLine, never on the header.
# Main associations: belongs_to :company, :branch (optional), :fiscal_period (optional), :source (polymorphic, optional), :reversal_of (optional); has_many :journal_lines.
class JournalEntry < ApplicationRecord
  # --- Enums ---
  enum :status, JOURNAL_ENTRY_STATUSES, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :fiscal_period, optional: true
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :posted_by_employee, class_name: "Employee", optional: true
  belongs_to :reversal_of, class_name: "JournalEntry", optional: true
  has_many :journal_lines, dependent: :destroy
  has_one :reversal_entry, class_name: "JournalEntry", foreign_key: :reversal_of_id, inverse_of: :reversal_of

  # --- Scopes ---
  scope :posted, -> { where(status: :posted) }
  scope :draft, -> { where(status: :draft) }
  scope :for_period, ->(period) { where(fiscal_period: period) }
  scope :between, ->(from, to) { where(entry_date: from..to) }
  scope :recent_first, -> { order(entry_date: :desc, created_at: :desc) }

  # --- Validations ---
  validates :entry_date, presence: true
  validates :event_key, presence: true, length: { maximum: 64 }

  # --- Methods ---
  # Persisted entries sum in SQL; a new (draft) entry sums its in-memory legs so
  # the balance can be checked before saving. Posting always writes both sides.
  def total_debit_cents
    return journal_lines.sum(:debit_cents) if persisted?

    association(:journal_lines).target.sum { |line| line.debit_cents.to_i }
  end

  def total_credit_cents
    return journal_lines.sum(:credit_cents) if persisted?

    association(:journal_lines).target.sum { |line| line.credit_cents.to_i }
  end

  def balanced?
    total_debit_cents == total_credit_cents
  end
end
