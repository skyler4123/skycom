# Links an addon_feature BillingResource to a BillingContract with its monthly price.
# Only addon_feature-type resources can be attached here (validated).
#
#   @contract.contract_features.active.each do |feature|
#     feature.monthly_flat_price_cents  # e.g. 500 for analytics_dashboard at $5/mo
#   end
#
# CalculatorService sums these for the features portion of the monthly bill.
#
class ContractFeature < ApplicationRecord
  attribute :monthly_flat_price_cents, :integer, default: 0

  belongs_to :billing_resource
  belongs_to :billing_contract

  has_many :daily_feature_logs, dependent: :destroy

  validates :billing_resource_id, uniqueness: { scope: :billing_contract_id,
                                                message: "is already assigned to this contract" }
  validates :monthly_flat_price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :lifecycle_status, { active: 0, disabled: 1 }, default: :active
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  validate :must_be_addon_feature_type

  private

  def must_be_addon_feature_type
    if billing_resource&.volumetric?
      errors.add(:billing_resource, "must be an addon_feature type to fit into contract_features")
    end
  end
end
