class SubscriptionPlan < ApplicationRecord
  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  has_many :subscription_plan_appointments, dependent: :destroy

  belongs_to :company
  belongs_to :branch, optional: true
end
