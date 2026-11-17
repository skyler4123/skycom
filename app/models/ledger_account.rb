# frozen_string_literal: true

# LedgerAccount — Atomic purpose: one General Ledger account a company can post journal lines to (the chart of accounts).
#
# Why it exists: every financial report — P&L, balance sheet, trial balance, cost-center P&L — is a projection of journal lines grouped by account; without an explicit account row there is nowhere to group them and the reports would have to be hardcoded per feature.
# How it works: belongs to a company and forms a self-referencing tree (parent/children) so headers like 'Current Assets' can own detail accounts. `normal_balance` is stored explicitly rather than derived from `account_type` because contra accounts (accumulated depreciation, sales returns) sit on the opposite side of their type. Posting writes JournalLine rows; this model is never mutated by the posting path.
# Main associations: belongs_to :company, :parent (optional); has_many :children, :journal_lines, :budget_lines.
class LedgerAccount < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :account_type, LEDGER_ACCOUNT_TYPES, prefix: true
  enum :normal_balance, NORMAL_BALANCES, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :parent, class_name: "LedgerAccount", optional: true, inverse_of: :children
  has_many :children, class_name: "LedgerAccount", foreign_key: :parent_id, inverse_of: :parent, dependent: :restrict_with_error
  has_many :journal_lines, dependent: :restrict_with_error
  has_many :budget_lines, dependent: :restrict_with_error

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:code) }

  # --- Validations ---
  validates :code, presence: true, length: { maximum: 32 }, uniqueness: { scope: :company_id }
  validates :name, presence: true, length: { maximum: 255 }
  validate :parent_same_company

  # --- Methods ---
  def debit_normal?
    normal_balance_debit?
  end

  private

  def parent_same_company
    return if parent.blank? || company_id.blank? || parent.company_id == company_id

    errors.add(:parent, "must belong to the same company")
  end
end
