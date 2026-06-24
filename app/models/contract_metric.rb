class ContractMetric < ApplicationRecord
  belongs_to :billing_resource
  belongs_to :billing_contract

  # Protect against duplicate configuration rows
  validates :billing_resource_id, uniqueness: { scope: :billing_contract_id, 
                                                message: "is already metered on this contract" }
  validates :free_allowance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :lifecycle_status, { active: 0, disabled: 1 }, default: :active

  # Validate that we aren't putting an feature gate inside the usage meter bridge
  validate :must_be_volumetric_type

  private

  def must_be_volumetric_type
    if billing_resource&.addon_feature?
      errors.add(:billing_resource, "must be a volumetric type to fit into contract_metrics")
    end
  end
end