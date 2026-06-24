class ContractFeature < ApplicationRecord
  belongs_to :billing_resource
  belongs_to :billing_contract

  # Prevent assigning the same feature multiple times to one contract
  validates :billing_resource_id, uniqueness: { scope: :billing_contract_id,
                                                message: "is already assigned to this contract" }
  validates :monthly_flat_price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :lifecycle_status, { active: 0, disabled: 1 }, default: :active

  # Validate that we aren't putting a volumetric metric inside the feature bridge
  validate :must_be_addon_feature_type

  private

  def must_be_addon_feature_type
    if billing_resource&.volumetric?
      errors.add(:billing_resource, "must be an addon_feature type to fit into contract_features")
    end
  end
end
