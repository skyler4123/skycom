class BillingResource < ApplicationRecord
  has_many :contract_features, dependent: :destroy
  has_many :contract_metrics, dependent: :destroy
  has_many :daily_usage_logs, dependent: :destroy

  # Ensure token/key identification alongside human names
  validates :name, presence: true, uniqueness: true

  enum :resource_type, { volumetric: 0, addon_feature: 1 }

  # Standardizing default lifecycle states
  enum :lifecycle_status, { active: 0, deprecated: 1, archived: 2 }, default: :active
end
