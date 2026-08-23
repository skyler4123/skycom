# frozen_string_literal: true

# CompanyUsageLog — Atomic purpose: opt-in per-action detail log explaining WHY
# a wallet balance moved (action_type mirrors CREDIT_USAGE_RATES keys, e.g.
# "create_order"). Hot-table safe: rows are written ONLY while the wallet's
# usage logging window is active (CompanyWallet#usage_logging_active?), so
# tracking can be enabled for a short period (default 5 minutes) to inspect
# live credit changes.
class CompanyUsageLog < ApplicationRecord
  VALID_ACTION_TYPES = CREDIT_USAGE_RATES.keys.map(&:to_s).freeze

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed
  belongs_to :company
  belongs_to :company_wallet
  belongs_to :source, polymorphic: true, optional: true

  validates :action_type, presence: true, inclusion: { in: VALID_ACTION_TYPES }
  validates :change_amount, :balance_after, presence: true, numericality: { only_integer: true }
end
