# Catalog of everything that can be metered or billed in the platform.
# Two types: volumetric (usage-based) and addon_feature (flat monthly fee).
#
# Seeded by Billing::SeedResourcesService:
#   volumetric:   orders, storage_mb, employees, branches, customers, api_calls, stock_mutations
#   addon_feature: hrm_attendance, inventory_advanced, analytics_dashboard, ...
#
#   BillingResource.volumetric     # scope
#   BillingResource.addon_feature  # scope
#   resource.volumetric?           # => true
#
class BillingResource < ApplicationRecord
  has_many :contract_features, dependent: :destroy
  has_many :contract_metrics, dependent: :destroy
  has_many :daily_metric_logs, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  enum :resource_type, { volumetric: 0, addon_feature: 1 }
  enum :lifecycle_status, { active: 0, deprecated: 1, archived: 2 }, default: :active
end
