# Links a volumetric BillingResource to a BillingContract with allowance and overage pricing.
# Only volumetric-type resources can be attached here (validated).
#
#   @contract.contract_metrics.active.each do |metric|
#     metric.free_allowance      # e.g. 200 orders/month included free
#     metric.unit_price_cents    # e.g. 10 cents per additional order
#   end
#
# CalculatorService computes overages by comparing DailyUsageLog sums against allowances.
#
class ContractMetric < ApplicationRecord
  attribute :free_allowance, :integer, default: 0
  attribute :unit_price_cents, :integer, default: 0

  belongs_to :billing_resource
  belongs_to :billing_contract

  validates :billing_resource_id, uniqueness: { scope: :billing_contract_id,
                                                message: "is already metered on this contract" }
  validates :free_allowance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :lifecycle_status, { active: 0, disabled: 1 }, default: :active
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  validate :must_be_volumetric_type

  private

  def must_be_volumetric_type
    if billing_resource&.addon_feature?
      errors.add(:billing_resource, "must be a volumetric type to fit into contract_metrics")
    end
  end
end
