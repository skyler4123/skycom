class BillingContract < ApplicationRecord
  belongs_to :company
  has_many :contract_features, dependent: :destroy
  has_many :contract_metrics, dependent: :destroy

  validates :contract_type, presence: true
  validates :start_date, presence: true
  
  # Enums for clean control flow
  enum :contract_type, { free_tier: 0, pay_as_you_go: 1, enterprise: 2 }
  enum :lifecycle_status, { draft: 0, active: 1, expired: 2, terminated: 3 }, default: :draft

  # Scopes are your best friend for high-speed multi-tenant runtime checks
  scope :currently_active, -> { 
    where(lifecycle_status: :active)
      .where("start_date <= ?", Time.current)
      .where("end_time IS NULL OR end_time >= ?", Time.current) 
  }

  # Helper method to duplicate template metrics cleanly during onboarding
  def attach_resource_metric!(resource, allowance:, pricing:)
    contract_metrics.create!(
      billing_resource: resource,
      name: resource.name,
      free_allowance: allowance,
      unit_price: pricing
    )
  end
end