# frozen_string_literal: true

# CompanyUsageLog — Atomic purpose: opt-in per-action detail log explaining WHY a
# wallet balance moved (action_type mirrors CREDIT_DEDUCTION_ACTION_TYPES).
#
# Why it exists: the hot path only keeps counters; when a live balance looks
# wrong, this table records the individual actions behind the movement for a short
# window.
# How it works: rows are written ONLY while the wallet's usage logging window is
# active (CompanyWallet#usage_logging_active?, default 5 minutes); action_type
# accepts the page action types plus top_up/deduction wallet defaults.
# Main associations: belongs_to :company, :company_wallet (required);
# belongs_to :source, polymorphic: true (optional).
class CompanyUsageLog < ApplicationRecord
  # Dual vocabulary: deduction-point actions (page action types, e.g.
  # "access_dashboard") + wallet movement defaults ("top_up" / "deduction"
  # from CompanyWallet#add_to! / #deduct_from!).
  VALID_ACTION_TYPES = CREDIT_DEDUCTION_ACTION_TYPES

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed
  belongs_to :company
  belongs_to :company_wallet
  belongs_to :source, polymorphic: true, optional: true

  validates :action_type, presence: true, inclusion: { in: VALID_ACTION_TYPES }
  validates :change_amount, :balance_after, presence: true, numericality: { only_integer: true }
end
