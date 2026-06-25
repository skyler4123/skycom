# The source of truth for what a company pays and what features it can access.
# Each company has exactly one active contract at a time.
#
#   # Get the active contract
#   company.active_billing_contract  # => BillingContract (or nil)
#
#   # Feature gate check
#   contract.contract_features.active.exists?(billing_resource: resource)
#
#   # Usage-based pricing checked by CalculatorService
#   contract.contract_metrics.active.each { |m| m.free_allowance }
#
class BillingContract < ApplicationRecord
  belongs_to :company
  has_many :contract_features, dependent: :destroy
  has_many :contract_metrics, dependent: :destroy

  validates :contract_type, presence: true
  validates :start_date, presence: true

  enum :contract_type, { free_tier: 0, pay_as_you_go: 1, enterprise: 2 }
  enum :lifecycle_status, { draft: 0, active: 1, expired: 2, terminated: 3 }, default: :draft

  scope :currently_active, -> {
    where(lifecycle_status: :active)
      .where("start_date <= ?", Time.current)
      .where("end_time IS NULL OR end_time >= ?", Time.current)
  }

  def attach_resource_metric!(resource, allowance:, pricing:)
    contract_metrics.create!(
      billing_resource: resource,
      name: resource.name,
      free_allowance: allowance,
      unit_price: pricing
    )
  end
end
