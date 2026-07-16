# frozen_string_literal: true

class BillingWallet < ApplicationRecord
  include Discard::Model

  belongs_to :company

  enum :lifecycle_status, { active: 0, archived: 1 }, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { base: 0, promo: 1 }

  validates :company, presence: true

  after_initialize :set_defaults, if: :new_record?
  after_update :auto_settle_unpaid_invoices, if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }

  private

  def set_defaults
    self.name ||= "#{company&.name || 'Company'} Wallet"
    self.currency ||= company&.currency_code_before_type_cast || 0
    self.promo_balance_cents ||= 0
    self.main_balance_cents ||= 0
    self.soft_debt_threshold_cents ||= -10000
    self.hide_billing_alerts = false if hide_billing_alerts.nil?
  end

  def auto_settle_unpaid_invoices
    company.auto_settle_unpaid_invoices
  end
end
